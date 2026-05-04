import os

def validate_magic_bytes(file_path: str) -> bool:
    """ Strict signature evaluations parsing MIME bounds without expensive DLLs avoiding corruptions entirely. """
    try:
        with open(file_path, "rb") as f:
            header = f.read(8)
        
        if not header:
            return False

        # JPEG: FF D8 FF
        if header.startswith(b'\xFF\xD8\xFF'):
            return True
        
        # PNG: 89 50 4E 47 0D 0A 1A 0A
        if header.startswith(b'\x89PNG\r\n\x1a\n'):
            return True

        # MP4: Expect 'ftyp' generally safely
        if b'ftyp' in header:
            return True
        
        # MOV (Quicktime) mappings safely structured
        if b'moov' in header or b'mdat' in header:
            return True
            
        print(f"Skipped media validation. Unrecognized header bytes: {header.hex()}")
        # We can loosely allow it returning true for unmapped types or strictly block. For now, strict:
        return False
    except Exception as e:
        print(f"Magic Byte extraction failed: {e}")
        return False
