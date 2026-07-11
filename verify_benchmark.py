import os
import time
import psutil
import torch
import numpy as np
from ultralytics import YOLO

def print_memory_cpu():
    process = psutil.Process(os.getpid())
    ram_mb = process.memory_info().rss / 1024 / 1024
    cpu_percent = psutil.cpu_percent(interval=None)
    return ram_mb, cpu_percent

def benchmark_model(model_path, task_type='detect'):
    print(f"\n======================================")
    print(f"Benchmarking: {model_path}")
    print(f"======================================")
    
    # Measure cold startup
    t0 = time.time()
    model = YOLO(model_path, task=task_type)
    t1 = time.time()
    print(f"Cold Startup Time: {t1 - t0:.2f}s")
    
    ram, cpu = print_memory_cpu()
    print(f"RAM Usage: {ram:.2f} MB | CPU: {cpu}%")
    
    # Create dummy image
    img = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)
    if task_type == 'classify' or 'best' in model_path:
        img = np.random.randint(0, 255, (320, 320, 3), dtype=np.uint8)
    
    # Warmup
    model(img, verbose=False)
    
    # Inference Latency
    latencies = []
    for _ in range(10):
        t0 = time.perf_counter()
        res = model(img, verbose=False)
        t1 = time.perf_counter()
        latencies.append((t1 - t0) * 1000)
        
    print(f"Warm Inference Latency: {np.mean(latencies):.2f} ms (avg over 10 runs)")
    
    ram, cpu = print_memory_cpu()
    print(f"Peak RAM Usage Post-Inference: {ram:.2f} MB | CPU: {cpu}%")
    
    return res[0]

if __name__ == "__main__":
    base_dir = "d:\\GeminiCLI\\FurSpeak-AI_Android_Build\\backend\\ml\\weights"
    pt_dog = os.path.join(base_dir, "yolov8n.pt")
    onnx_dog = os.path.join(base_dir, "yolov8n.onnx")
    
    # Initialize psutil CPU polling
    psutil.cpu_percent(interval=None)
    
    res_pt = benchmark_model(pt_dog, 'detect')
    res_onnx = benchmark_model(onnx_dog, 'detect')
    
    print("\n--- DETECTIONS COMPARISON (YOLOv8n) ---")
    print(f"PyTorch Boxes: {res_pt.boxes.data.shape if res_pt.boxes else 'None'}")
    print(f"ONNX Boxes: {res_onnx.boxes.data.shape if res_onnx.boxes else 'None'}")
    
    pt_beh = os.path.join(base_dir, "best.pt")
    onnx_beh = os.path.join(base_dir, "best.onnx")
    
    res_pt_beh = benchmark_model(pt_beh, 'detect') # Changing to detect since it outputs boxes
    res_onnx_beh = benchmark_model(onnx_beh, 'detect')
    
    print("\n--- CLASSIFICATION COMPARISON (Best) ---")
    if res_pt_beh.boxes and len(res_pt_beh.boxes) > 0:
        print(f"PyTorch Boxes: {res_pt_beh.boxes.data.shape}")
    else:
        print("PyTorch Boxes: None")
        
    if res_onnx_beh.boxes and len(res_onnx_beh.boxes) > 0:
        print(f"ONNX Boxes: {res_onnx_beh.boxes.data.shape}")
    else:
        print("ONNX Boxes: None")
