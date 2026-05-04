import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.services.video_service import VideoService

def test_media():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    test_media_dir = os.path.join(base_dir, 'test_media')
    
    videos = ['dog.mp4', 'cat.mp4', 'hamster.mp4']
    
    for v in videos:
        print(f"\n{'='*50}\nTESTING: {v}\n{'='*50}")
        path = os.path.join(test_media_dir, v)
        try:
            res = VideoService.process_video(
                video_path=path,
                base_url="",
                source_tag="test_script",
                request_id=f"test_{v.split('.')[0]}",
                start_time=None
            )
            print(f">>> FINAL SUCCESS: {res.emotion} ({res.confidence}%)")
        except Exception as e:
            print(f">>> FINAL ERROR: {e}")

if __name__ == '__main__':
    test_media()
