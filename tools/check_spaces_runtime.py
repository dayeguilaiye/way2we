"""T02 local two/three-account flow; validate every actual response against OpenAPI."""
import json, os, re, time, uuid
from urllib.request import Request,urlopen
from urllib.error import HTTPError
from urllib.parse import urlparse
from check_contract import spec,validator
base=os.environ.get('API_BASE_URL','http://127.0.0.1:8080')
mail=os.environ.get('MAILPIT_URL','http://127.0.0.1:8025')
assert all(urlparse(v).hostname in ('localhost','127.0.0.1') for v in (base,mail))
seen=set()
def call(method,path,status=200,data=None,token=None,key=None):
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 if key:headers['Idempotency-Key']=key
 req=Request(base+path,method=method,headers=headers,data=json.dumps(data).encode() if data is not None else None)
 try:r=urlopen(req,timeout=15)
 except HTTPError as e:r=e
 with r:
  body=json.load(r);assert r.status==status,(method,path,r.status,body)
  rid=r.headers['X-Request-ID'];assert rid not in seen;seen.add(rid)
  endpoint=path.split('?')[0]
  for template,operations in spec['paths'].items():
   if re.fullmatch(re.sub(r'\{[^}]+\}',r'[^/]+',template),endpoint) and method.lower() in operations:
    schema=operations[method.lower()]['responses'][str(status)]
    if '$ref' in schema:schema=spec['components']['responses'][schema['$ref'].split('/')[-1]]
    validator(schema['content']['application/json']['schema']).validate(body);break
  else:raise AssertionError('No contract for '+path)
  return body

def login(label):
 email=f't02-{label}-{uuid.uuid4().hex}@example.test'
 call('POST','/v1/auth/email-codes',202,{'email':email})
 for _ in range(50):
  with urlopen(mail+'/api/v1/messages') as r:messages=json.load(r)['messages']
  for m in messages:
   if any(t['Address']==email for t in m['To']):
    with urlopen(mail+'/api/v1/message/'+m['ID']) as r:detail=json.load(r)
    code=re.search(r'\b\d{6}\b',detail['Text']).group()
    return call('POST','/v1/auth/sessions',201,{'email':email,'code':code})['access_token']
  time.sleep(.2)
 raise AssertionError('Mail not delivered')
def write(token,path,data=None,status=200,key=None,method='POST'):
 return call(method,path,status,data,token,key or str(uuid.uuid4()))
if __name__=='__main__':
 a,b,c=login('a'),login('b'),login('c')
 key=str(uuid.uuid4());data={'name':'一起的小日子','nickname':'阿禾'}
 created=write(a,'/v1/spaces',data,201,key);assert write(a,'/v1/spaces',data,201,key)==created
 sid=created['space']['id'];assert created['member']['balance']==0
 call('GET','/v1/spaces',token=a);call('GET',f'/v1/spaces/{sid}',token=a)
 first=write(a,f'/v1/spaces/{sid}/invitations',status=201)
 call('POST','/v1/invitations/preview',data={'invite_code':first['invite_code']},token=b)
 joined=write(b,'/v1/invitations/accept',{'invite_code':first['invite_code'],'nickname':'小满'})
 assert joined['status']=='joined'
 second=write(a,f'/v1/spaces/{sid}/invitations',status=201)
 waiting=write(c,'/v1/invitations/accept',{'invite_code':second['invite_code'],'nickname':'朋友'})
 assert waiting['status']=='waiting'
 call('GET',f'/v1/spaces/{sid}/members',404,token=c)
 call('GET',f'/v1/invitations/{waiting["id"]}',token=c)
 call('GET',f'/v1/spaces/{sid}/invitations',token=b)
 done=write(b,f'/v1/spaces/{sid}/invitations/{waiting["id"]}/approve')
 assert done['status']=='joined' and len(done['required_member_ids'])==2
 page=call('GET',f'/v1/spaces/{sid}/members?limit=2',token=c)
 assert len(page['items'])==2 and page['next_cursor']
 from urllib.parse import urlencode
 tail=call('GET',f'/v1/spaces/{sid}/members?'+urlencode({'cursor':page['next_cursor']}),token=c)
 assert len(tail['items'])==1
 write(b,f'/v1/spaces/{sid}/members/me',{'nickname':'小满呀'},method='PATCH')
 call('POST','/v1/invitations/preview',404,{'invite_code':first['invite_code']},c)
 for _ in range(30):
  notices=call('GET','/v1/notifications',token=c)
  if notices['items']:break
  time.sleep(.2)
 assert notices['items']
 notice=notices['items'][0]
 read=write(c,f'/v1/notifications/{notice["id"]}/read',method='PUT');assert read['read_at']
 call('GET','/v1/notifications?unread_only=true',token=c)
 print(f'OK: T02 real email accounts, spaces, multi-member admission, pagination and notification; {len(seen)} contract-validated exchanges.')
