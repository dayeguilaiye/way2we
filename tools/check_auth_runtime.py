"""Exercise T01 against the local API and Mailpit, validating actual API responses."""
import json
import os
import re
import time
import uuid
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from urllib.parse import urlparse
from check_contract import spec, validator

base = os.environ.get('API_BASE_URL', 'http://127.0.0.1:8080')
inbox = os.environ.get('MAILPIT_URL', 'http://127.0.0.1:8025')
for origin in (base, inbox):
    assert urlparse(origin).hostname in {'127.0.0.1', 'localhost'}, 'Local checks only'
seen = set()
def call(method, path, status, data=None, token=None, key=None):
    headers = {'Content-Type': 'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    if key: headers['Idempotency-Key'] = key
    req = Request(base + path, method=method, headers=headers,
                  data=json.dumps(data).encode() if data is not None else None)
    try: response = urlopen(req, timeout=10)
    except HTTPError as error: response = error
    with response:
        assert response.status == status, (method, path, response.status)
        request_id = response.headers['X-Request-ID']
        assert request_id and request_id not in seen
        seen.add(request_id)
        raw = response.read()
        if status == 204:
            assert not raw
            return None
        body = json.loads(raw)
        schema = spec['paths'][path][method.lower()]['responses'][str(status)]
        if '$ref' in schema:
            schema = spec['components']['responses'][schema['$ref'].split('/')[-1]]
        validator(schema['content']['application/json']['schema']).validate(body)
        if status >= 400: assert body['request_id'] == request_id
        return body

def receive(email):
    for _ in range(30):
        with urlopen(inbox+'/api/v1/messages', timeout=5) as response: messages = json.load(response)['messages']
        for message in messages:
            if any(to['Address'] == email for to in message['To']):
                with urlopen(inbox+'/api/v1/message/'+message['ID'], timeout=5) as response: body = json.load(response)
                return re.search(r'\b[0-9]{6}\b', body['Text']).group()
        time.sleep(.3)
    raise AssertionError('Local code email not received')

email = 'runtime-'+uuid.uuid4().hex+'@example.test'
call('POST','/v1/auth/email-codes',422,{'email':'invalid'})
call('POST','/v1/auth/email-codes',202,{'email':email})
call('POST','/v1/auth/email-codes',429,{'email':email})
code = receive(email)
call('POST','/v1/auth/sessions',401,{'email':email,'code':'000000' if code!='000000' else '111111'})
session = call('POST','/v1/auth/sessions',201,{'email':email,'code':code})
token = session['access_token']
call('GET','/v1/me',401)
me = call('GET','/v1/me',200,token=token)
key = str(uuid.uuid4())
change = {'display_name':'本地验证','theme':'celadon'}
saved = call('PATCH','/v1/me',200,change,token,key)
assert saved['id'] == me['id'] and saved['display_name']=='本地验证' and saved['theme']=='celadon'
assert call('PATCH','/v1/me',200,change,token,key) == saved
call('PATCH','/v1/me',409,{'theme':'rose'},token,key)
call('PATCH','/v1/me',400,{'theme':None},token,str(uuid.uuid4()))
call('PATCH','/v1/me',422,{'display_name':''},token,str(uuid.uuid4()))
call('DELETE','/v1/auth/session',204,token=token)
call('GET','/v1/me',401,token=token)
call('POST','/v1/auth/sessions',401,{'email':email,'code':code})
print('OK: T01 local SMTP delivery, login, profile, replay, errors and revocation; 15 HTTP exchanges validated.')
