import os
import shutil
from uuid import uuid4
from fastapi import UploadFile
from contextlib import contextmanager
from backend.core.config import Config

class FileManager:
    @staticmethod
    def save_upload_file_temp(upload_file: UploadFile) -> str:
        file_ext = os.path.splitext(upload_file.filename)[-1].lower()
        unique_filename = f"{uuid4().hex}{file_ext}"
        temp_path = os.path.join(Config.TEMP_DIR, unique_filename)
        
        with open(temp_path, "wb") as f:
            shutil.copyfileobj(upload_file.file, f)
        return temp_path

    @staticmethod
    def delete_file(file_path: str):
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except OSError as e:
                print(f"Error deleting temporary file {file_path}: {e}")

@contextmanager
def managed_temp_file(upload_file: UploadFile):
    temp_path = None
    try:
        temp_path = FileManager.save_upload_file_temp(upload_file)
        yield temp_path
    finally:
        if temp_path:
            FileManager.delete_file(temp_path)
