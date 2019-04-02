execute_process(
    COMMAND "${AWK_BIN}"
        "-f" "${AWK_SCRIPT}"
        "-v" "FILE_BASE_NAME=${FILE_BASE_NAME}"
        "--"
        "${INPUT_FILE}"
    OUTPUT_FILE "${OUTPUT_FILE}"
)
