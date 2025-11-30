#!/usr/bin/env bats

IMAGE_NAME="mt4-compiler-test"

setup() {
    # Build image before tests to ensure it exists and is up to date
    # We rely on Docker caching to make this fast if already built
    if [[ -z "${SKIP_BUILD}" ]]; then
        docker build -t "$IMAGE_NAME" .
        export SKIP_BUILD=true
    fi
}

@test "Success Case: Compile valid MQ4 file" {
    rm -f tests/Success.ex4
    run docker run --rm -v "$(pwd)/tests:/home/wine/tests" "$IMAGE_NAME" /home/wine/tests/Success.mq4
    
    echo "$output"
    [ "$status" -eq 0 ]
    [ -f "tests/Success.ex4" ]
    rm tests/Success.ex4
}

@test "Failure Case: Compile invalid MQ4 file" {
    rm -f tests/Fail.ex4
    run docker run --rm -v "$(pwd)/tests:/home/wine/tests" "$IMAGE_NAME" /home/wine/tests/Fail.mq4
    
    echo "$output"
    [ "$status" -ne 0 ]
    [ ! -f "tests/Fail.ex4" ]
}
