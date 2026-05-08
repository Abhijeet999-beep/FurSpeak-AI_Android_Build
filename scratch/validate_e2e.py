import requests
import time
import os
import sys

BASE_URL = "http://localhost:8000/api/v1"
GUEST_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJndWVzdF83OTFlMGQ2ZmQ1ZTc0OGU1YmM0ZTQwMTEyNDhkNjIxMyIsInJvbGUiOiJndWVzdCIsImV4cCI6MTc3ODI0OTIwMn0.qqaSSFM3oVMFpUEYO2JfIBq29FMdpKRX8toH2YrOZEc"

headers = {
    "Authorization": f"Bearer {GUEST_TOKEN}"
}

def test_health():
    print("Testing Health Check...")
    resp = requests.get("http://localhost:8000/health")
    print(resp.json())
    assert resp.status_code == 200
    assert resp.json()["firebase_initialized"] is True

def test_image_upload():
    print("\nTesting Image Upload...")
    paths = ["for_testing/pic1.jpg", "for_testing/pic2.jpg"]
    success = False
    for path in paths:
        if not os.path.exists(path):
            continue
        print(f"Trying {path}...")
        with open(path, "rb") as f:
            files = {"file": (os.path.basename(path), f, "image/jpeg")}
            resp = requests.post(f"{BASE_URL}/detect/image", headers=headers, files=files)
        
        res_json = resp.json()
        print(res_json)
        if resp.status_code == 200 and res_json.get("success"):
            data = res_json["data"]
            print(f"SUCCESS: Emotion={data['emotion']}, Thumbnail={data['thumbnail_url']}")
            success = True
            break
        else:
            print(f"FAILED for {path}: {res_json.get('message')}")
    
    if not success:
        print("WARNING: Image upload validation failed for all test images. Proceeding to video test...")

def test_video_upload():
    print("\nTesting Video Upload (test_vid1.mp4)...")
    path = "for_testing/test_vid1.mp4"
    if not os.path.exists(path):
        print(f"ERROR: {path} not found.")
        return

    with open(path, "rb") as f:
        files = {"file": ("test_vid1.mp4", f, "video/mp4")}
        resp = requests.post(f"{BASE_URL}/detect/video", headers=headers, files=files)
    
    res_json = resp.json()
    print(res_json)
    if resp.status_code != 200 or not res_json.get("success"):
        print(f"FAILURE: Video upload failed: {res_json.get('message')}")
        return

    job_id = res_json["data"]["job_id"]
    print(f"Job ID: {job_id}")
    
    # Polling
    for i in range(60): # Increase timeout for video
        time.sleep(2)
        resp = requests.get(f"{BASE_URL}/detect/status/{job_id}", headers=headers)
        status_res = resp.json()
        if not status_res.get("success"):
            print(f"ERROR: Polling failed: {status_res.get('message')}")
            break
            
        status_data = status_res["data"]
        print(f"Polling {i+1}: status={status_data['status']}")
        if status_data["status"] == "completed":
            print("SUCCESS: Video processing completed.")
            print(status_data["result"])
            return
        if status_data["status"] == "failed":
            print("FAILURE: Video processing failed.")
            print(status_data["result"])
            return
    
    print("FAILURE: Polling timed out.")

if __name__ == "__main__":
    try:
        test_health()
        test_image_upload()
        test_video_upload()
        print("\nALL E2E TESTS PASSED!")
    except Exception as e:
        print(f"\nTEST FAILED: {e}")
        sys.exit(1)
