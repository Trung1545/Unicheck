import pytest
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    response = client.get('/health')
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success'] is True
    assert json_data['data']['status'] == 'UP'
    assert json_data['errorCode'] is None

def test_extract_embedding(client):
    response = client.post('/api/v1/face/extract-embedding', json={})
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success'] is True
    assert 'embedding' in json_data['data']
    assert len(json_data['data']['embedding']) == 128
    assert json_data['errorCode'] is None

def test_check_liveness(client):
    response = client.post('/api/v1/face/check-liveness', json={})
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success'] is True
    assert json_data['data']['is_live'] is True
    assert json_data['errorCode'] is None
