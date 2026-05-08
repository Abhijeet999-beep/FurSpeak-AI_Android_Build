import os

def validate_magic_bytes(file_path: str) -> bool:
    """
    Validates magic bytes to ensure file is an actual media file.
    Only supports common image and video formats.
    """
    if not os.path.exists(file_path):
        return False
        
    try:
        with open(file_path, "rb") as f:
            header = f.read(12)
            
        if not header:
            return False
            
        # JPEG
        if header.startswith(b'\xff\xd8\xff'):
            return True
        # PNG
        elif header.startswith(b'\x89PNG\r\n\x1a\n'):
            return True
        # MP4 (ftyp)
        elif b'ftyp' in header[4:12]:
            return True
            
        return False
    except Exception:
        return False

def is_valid_video_extension(filename: str) -> bool:
    return filename.lower().endswith('.mp4')
