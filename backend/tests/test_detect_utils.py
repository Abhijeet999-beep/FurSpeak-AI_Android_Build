import pytest
import os
import tempfile
from detect_utils import error_response, log_debug_info

def test_error_response():
    """Test error response function returns correct structure"""
    error_msg = "Test error message"
    response = error_response(error_msg)
    
    assert response["emotion"] == "unknown"
    assert response["confidence"] == 0.0
    assert response["caption"] == error_msg
    assert "timestamp" in response
    assert response["video_info"] is None

def test_log_debug_info():
    """Test debug logging function"""
    # This should not raise any exceptions
    log_debug_info("Test debug message")

def test_temp_directory_creation():
    """Test that temp directory is created"""
    from detect_utils import TEMP_DIR
    assert os.path.exists(TEMP_DIR)

def test_behavior_classes_defined():
    """Test that behavior classes are properly defined"""
    from detect_utils import behavior_classes
    expected_classes = ['relax', 'happy', 'angry', 'frown', 'alert']
    assert behavior_classes == expected_classes
