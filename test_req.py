import urllib.request, os

def post_file(filename):
    boundary = 'wL36Yn8afVp8Ag7AmP8qZ0SA4n1v9T'
    with open(filename, 'rb') as f:
        file_body = f.read()
    data = []
    data.append(b'--' + boundary.encode('utf-8'))
    data.append(f'Content-Disposition: form-data; name="file"; filename="{os.path.basename(filename)}"'.encode('utf-8'))
    data.append(b'Content-Type: image/jpeg')
    data.append(b'')
    data.append(file_body)
    data.append(b'--' + boundary.encode('utf-8') + b'--')
    data.append(b'')
    body = b'\r\n'.join(data)
    req = urllib.request.Request('http://localhost:8000/api/v1/detect/image', data=body)
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')
    req.add_header('Authorization', 'Bearer development-mock-token')
    try:
        res = urllib.request.urlopen(req)
        print(f'{filename} RESPONSE:', res.read().decode())
    except urllib.error.HTTPError as e:
        print(f'{filename} ERROR:', e.code, e.read().decode())

post_file('test_media/dog.jpg')
post_file('test_media/cat.jpg')
post_file('test_media/hamster.jpg')
