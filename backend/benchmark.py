import time
import requests
import os
import concurrent.futures
import urllib.request

# Create dummy structures for test cases
if not os.path.exists("test_media"):
    os.makedirs("test_media")

def ensure_test_files():
    large_path = "test_media/too_large.mp4"
    if not os.path.exists(large_path):
        with open(large_path, "wb") as f:
            f.seek((51 * 1024 * 1024) - 1)
            f.write(b"\0")
            
    dummy_img = "test_media/dummy.jpg"
    if not os.path.exists(dummy_img):
        with open(dummy_img, "wb") as f:
            f.write(b"fake image data")

def generate_realistic_video(path, duration_sec=5, fps=24, resolution=(640, 480)):
    if os.path.exists(path):
        return
    print(f"Downloading realistic sample video '{path}'... Please wait.")
    url = "https://www.w3schools.com/html/mov_bbb.mp4"
    try:
        urllib.request.urlretrieve(url, path)
        # Randomize file hash safely by appending bytes to avoiding exact Cache Stampede matches across Queue Test (Test A)
        with open(path, "ab") as f:
            f.write(os.urandom(duration_sec * 100)) # Random padding
    except Exception as e:
        print(f"Ensure internet connection: {e}")

def test_endpoint(file_path, req_id="1", modifier=None):
    start = time.time()
    try:
        with open(file_path, "rb") as f:
            files = {"file": (os.path.basename(file_path), f, "application/octet-stream")}
            
            headers = {
                "x-source": f"benchmark-script-{req_id}",
                "Authorization": "Bearer development-mock-token"
            }
            if modifier:
                headers["x-modifier"] = modifier
                
            # Select correct endpoint based on extension
            endpoint = "/api/v1/detect/video" if file_path.endswith(('.mp4', '.avi', '.mov')) else "/api/v1/detect/image"
            target_url = f"http://localhost:8000{endpoint}"
            
            response = requests.post(target_url, files=files, headers=headers)
            
        latency = round(time.time() - start, 2)
        print(f"[REQ {req_id}] [{response.status_code}] Latency: {latency}s")
        if response.status_code != 200:
            print(f"   -> {response.text}")
        return response.status_code, latency
    except Exception as e:
        print(f"[REQ {req_id}] Failed. {e}")
        return 500, 0

def burst_test(file_path, concurrent_count=10):
    print(f"\n🚀 Running BURST TEST with {concurrent_count} requests simultaneously on {file_path}")
    start = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_count) as executor:
        futures = {executor.submit(test_endpoint, file_path, i): i for i in range(concurrent_count)}
        for future in concurrent.futures.as_completed(futures):
            future.result()
            
    print(f"🏁 Burst Test Completed in {round(time.time() - start, 2)}s!\n")

def test_a_heavy_queue():
    print("\n--- TEST A: HEAVY QUEUE ---")
    print("Uploading 5 varying videos. Queue wait should increase linearly.")
    # We generate 5 unique small videos so they don't cache match!
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        for i in range(5):
            path = f"test_media/queue_vid_{i}.mp4"
            generate_realistic_video(path, duration_sec=2) # 2 sec videos
            executor.submit(test_endpoint, path, f"QueueTest-{i}")

def test_b_timeout_pressure():
    print("\n--- TEST B: TIMEOUT PRESSURE ---")
    print("Uploading a VERY heavy 60s video with extremely low frontend timeout to trigger native Cancellations.")
    # Assuming global timeout config > 120s, if we send payload but locally abort
    path = "test_media/heavy_vid.mp4"
    generate_realistic_video(path, duration_sec=5) # 5 seconds is heavy enough for YOLO to stack bounds 
    try:
        with open(path, "rb") as f:
            files = {"file": (os.path.basename(path), f, "application/octet-stream")}
            headers = {"Authorization": "Bearer development-mock-token"}
            requests.post(API_URL, files=files, headers=headers, timeout=2.0) # Abort abruptly
    except requests.exceptions.ReadTimeout:
        print("[REQ TimeoutTest] [504] Latency: 2.0s -> Caught Local Abort! Check backend logs for Worker Skip confirmation.")

def test_c_cache_burst():
    print("\n--- TEST C: CACHE STAMPEDE BURST ---")
    print("Uploading exactly identical video 5 times concurrently.")
    path = "test_media/stampede_vid.mp4"
    generate_realistic_video(path, duration_sec=3)
    burst_test(path, 5)

if __name__ == "__main__":
    ensure_test_files()
    print("--- FurSpeak API Pre-Production Stress Matrix ---")
    
    # 1. Verification of Stampedes
    test_c_cache_burst()
    
    # 2. Verification of Queue limits cleanly distributing uniquely handled logic
    test_a_heavy_queue()
    
    # 3. Verification of timeouts abandoning workers seamlessly natively
    test_b_timeout_pressure()
