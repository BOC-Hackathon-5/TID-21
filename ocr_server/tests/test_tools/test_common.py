import tempfile
import os
import shutil

import pytest

from magic_pdf.tools.common import do_parse


@pytest.mark.parametrize("method", ["auto", "txt", "ocr"])
def test_common_do_parse(method):
    # setup
    unitest_dir = "/tmp/magic_pdf/unittest/tools"
    filename = "fake"
    os.makedirs(unitest_dir, exist_ok=True)

    temp_output_dir = tempfile.mkdtemp(dir="/tmp/magic_pdf/unittest/tools")

    # run
    with open("tests/test_tools/assets/common/cli_test_01.pdf", "rb") as f:
        bits = f.read()
    do_parse(temp_output_dir,
             filename,
             bits, [],
             method,
             False,
             f_dump_content_list=True)

    # check
    base_output_dir = os.path.join(temp_output_dir, f"fake/{method}")

    r = os.stat(os.path.join(base_output_dir, "content_list.json"))
    assert r.st_size > 5000

    r = os.stat(os.path.join(base_output_dir, f"{filename}.md"))
    assert r.st_size > 7000

    r = os.stat(os.path.join(base_output_dir, "middle.json"))
    assert r.st_size > 200000

    r = os.stat(os.path.join(base_output_dir, "model.json"))
    assert r.st_size > 15000

    r = os.stat(os.path.join(base_output_dir, "origin.pdf"))
    assert r.st_size > 500000

    r = os.stat(os.path.join(base_output_dir, "layout.pdf"))
    assert r.st_size > 500000

    r = os.stat(os.path.join(base_output_dir, "spans.pdf"))
    assert r.st_size > 500000

    os.path.exists(os.path.join(base_output_dir, "images"))
    os.path.isdir(os.path.join(base_output_dir, "images"))

    # teardown
    shutil.rmtree(temp_output_dir)
