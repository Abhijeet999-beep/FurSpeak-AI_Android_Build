import os
import tempfile
import pytest
from backend.utils.media_validator import validate_magic_bytes, is_valid_video_extension

def test_is_valid_video_extension():
    assert is_valid_video_extension("test.mp4") is True
    assert is_valid_video_extension("test.MP4") is True
    assert is_valid_video_extension("test.png") is False

def test_validate_magic_bytes_non_existent():
    assert validate_magic_bytes("non_existent_file.jpg") is False

def test_validate_magic_bytes_empty():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = tmp.name
    try:
        assert validate_magic_bytes(tmp_path) is False
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def test_validate_magic_bytes_jpeg():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(b'\xff\xd8\xff\xe0\x00\x10JFIF')
        tmp_path = tmp.name
    try:
        assert validate_magic_bytes(tmp_path) is True
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def test_validate_magic_bytes_png():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR')
        tmp_path = tmp.name
    try:
        assert validate_magic_bytes(tmp_path) is True
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def test_validate_magic_bytes_mp4():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(b'\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00')
        tmp_path = tmp.name
    try:
        assert validate_magic_bytes(tmp_path) is True
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def test_validate_magic_bytes_invalid():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(b'invalid_header_content_here')
        tmp_path = tmp.name
    try:
        assert validate_magic_bytes(tmp_path) is False
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
