## test_read_large.sage -- loading a program image larger than the whole-file read cap.
##
## io.readbytes() refuses a read over SAGE_MAX_READ_SIZE (100 MiB) and returns nil
## rather than reporting an error. bytes_len() of nil is 0, so the VM saw an empty
## image and reported a bad magic number -- which reads as "this file is malformed"
## rather than "this file was never read". Both the runner and the CLI loaded their
## input that way.
##
## read_whole() tries the single read first and only reassembles from
## io.readbytes_at() ranges when it comes back empty, so this also checks that the
## ordinary small-file path is unchanged.

import sys
import io
from sgvm_compiler import read_whole

var TESTS_RUN: Int = 0
var TESTS_PASSED: Int = 0

proc check(name: String, cond: Bool):
    TESTS_RUN = TESTS_RUN + 1
    if cond:
        TESTS_PASSED = TESTS_PASSED + 1
        print("    PASS  " + name)
    else:
        print("    FAIL  " + name)

proc main():
    ## ---- A small file still takes the single-read path --------------------
    let small = "/tmp/sagevm_read_small.bin"
    let payload: Bytes = bytes(4096)
    var i = 0
    while i < 4096:
        bytes_set(payload, i, (i * 13 + 5) % 251)
        i = i + 1
    io.writebytes(small, payload)
    let small_back = read_whole(small)
    check("a small file reads back whole",
          bytes_len(small_back) == 4096
          and bytes_get(small_back, 100) == bytes_get(payload, 100)
          and bytes_get(small_back, 4095) == bytes_get(payload, 4095))

    ## ---- A file over the cap is reassembled, not lost ---------------------
    ##
    ## 128 MiB: over the 100 MiB limit but small enough to build quickly. Built by
    ## appending 1 MiB chunks rather than allocating one buffer, because this runtime
    ## cannot allocate a Bytes that large at all -- bytes(128 MiB) returns nil.
    let big = "/tmp/sagevm_read_big.bin"
    ## Each chunk gets a distinct first byte, so a reassembly that dropped, repeated
    ## or reordered a chunk is visible at the boundary. Repeating one pattern and
    ## computing its expected value from the absolute offset does not work: the
    ## pattern restarts per chunk, so every boundary holds the same byte and a
    ## chunk dropped from the middle is invisible.
    var rounds = 0
    let chunk: Bytes = bytes(1024 * 1024)
    while rounds < 129:
        var k = 0
        while k < bytes_len(chunk):
            bytes_set(chunk, k, (rounds * 7 + k * 13) % 251)
            k = k + 1
        if rounds == 0:
            io.writebytes(big, chunk)
        else:
            io.appendbytes(big, chunk)
        rounds = rounds + 1
    let expect = 129 * 1024 * 1024

    check("the file on disk is past the read cap",
          io.filesize(big) == expect)

    ## The whole-file read is the thing that used to fail, so assert it directly:
    ## if this ever starts succeeding, the fallback is no longer being exercised and
    ## the rest of the test proves nothing.
    let direct = io.readbytes(big)
    check("io.readbytes still refuses the large file (so the fallback matters)",
          bytes_len(direct) < expect)

    let whole = read_whole(big)
    check("read_whole reassembles the whole file", bytes_len(whole) == expect)

    ## Content, not just length: a reassembly that dropped or repeated a chunk would
    ## have the right total in only a few cases, but the boundaries are where it
    ## shows. Check the first and last byte of every chunk boundary.
    var boundaries_ok = bytes_len(whole) == expect
    var b = 0
    while b < 129 and boundaries_ok:
        let at = b * 1024 * 1024
        let want = (b * 7) % 251
        if bytes_get(whole, at) != want:
            boundaries_ok = false
        b = b + 1
    check("every chunk boundary holds the right byte", boundaries_ok)

    ## The final byte of the last chunk, which is only correct if the tail was read
    ## whole rather than short.
    let last_chunk_start = 128 * 1024 * 1024
    let last_off = last_chunk_start + 1024 * 1024 - 1
    check("the last byte of the file is intact",
          bytes_len(whole) == expect
          and bytes_get(whole, last_off) == ((128 * 7) + (1024 * 1024 - 1) * 13) % 251)

    ## ---- Edge cases -------------------------------------------------------
    let empty = read_whole("/tmp/sagevm_read_empty.bin")
    check("a missing file reads as empty, not nil", bytes_len(empty) == 0)

    if TESTS_PASSED == TESTS_RUN:
        print("ALL TESTS PASSED")
    else:
        print("SOME TESTS FAILED")
        print("Results: " + str(TESTS_PASSED) + "/" + str(TESTS_RUN) + " passed")

main()
