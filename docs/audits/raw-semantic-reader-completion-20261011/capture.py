"""Original reader execution; the terminal guard receipt writer stays outside the guarded tree."""
import argparse,subprocess,sys
from common import *

def specs():
    raw=local(PRIOR/"qualification-plan.json").read_bytes();value=json.loads(raw)
    need(raw==canonical(value),"complete canonical original prerequisite plan")
    return value["specifications"]

def instrument(spec):
    return {arg:dict(body=(body:=local(arg).read_bytes()).decode(),identity=pin(body))
            for arg in spec["command"] if Path(arg).is_file()}

def filename(attempt,name,suffix):
    need(attempt.isalnum() and name in specs(),"explicit safe original reader role/attempt")
    return "reader-"+attempt+"-"+name+suffix

def qualify(row,spec):
    need(type(row["status"]) is int and row["status"]==0 and row["command"]==spec["command"]
         and row["specification"]==spec and row["revision"]==REVISION
         and row["programmes"]==row["programmes_after"]==programs()
         and row["direct_instruments"]==row["direct_instruments_after"]==instrument(spec),
         "actual unchanged original command, status and complete execution source epoch")
    need(row["stderr"]=="" and spec["match"] in ("whole","terminal")
         and (row["stdout"]==spec["stdout"] if spec["match"]=="whole" else row["stdout"].endswith(spec["stdout"])),
         "complete declared original success stream role")
    for s in ("stdout","stderr"):
        need(local(row[s+"_path"]).read_bytes()==row[s].encode(),"whole retained actual native reader stream")

def child(attempt,name):
    spec=specs()[name];row=load(filename(attempt,name,"-started.json"))
    need(row["specification"]==spec and row["programmes"]==programs(),"whole declared reader and execution programme epoch before child")
    with local(row["stdout_path"],exists=False).open("xb",buffering=0) as out,local(row["stderr_path"],exists=False).open("xb",buffering=0) as err:
        result=subprocess.run(spec["command"],stdout=out,stderr=err)
    actual=dict(**row,status=result.returncode,stdout=local(row["stdout_path"]).read_text(),stderr=local(row["stderr_path"]).read_text(),
                programmes_after=programs(),direct_instruments_after=instrument(spec))
    save(filename(attempt,name,"-actual.json"),actual)
    qualify(actual,spec)
    print("PASS complete unchanged original prerequisite",name)

def execute(attempt,name):
    spec=specs()[name]
    need(programs()==load("execution-plan.json")["programmes"],"complete frozen original-reader execution dependency set")
    row=dict(command=spec["command"],specification=spec,revision=REVISION,owner=LEAF,scope=SCOPE,
        programmes=programs(),direct_instruments=instrument(spec),source=pin(local(BASE/"intake-before.json").read_bytes()),
        stdout_path=str(BASE/filename(attempt,name,".stdout.txt")),stderr_path=str(BASE/filename(attempt,name,".stderr.txt")),
        condition="Original unchanged reader only. Native result is not fully source-qualified until whole after-corpus custody also succeeds. First A/B failures remain non-success.")
    save(filename(attempt,name,"-started.json"),row)
    command=["scripts/run_with_ram_guard.sh","--","python3","-B",str(BASE/"capture.py"),"--child","--attempt",attempt,"--name",name]
    outer=dict(command=command,programmes=programs(),specification=spec,
        stdout_path=str(BASE/filename(attempt,name,"-guard.stdout.txt")),stderr_path=str(BASE/filename(attempt,name,"-guard.stderr.txt")),
        condition="This writer is outside the guarded process tree. Every terminal guard code and complete available stream retains before judgment.")
    save(filename(attempt,name,"-guard-started.json"),outer)
    with local(outer["stdout_path"],exists=False).open("xb",buffering=0) as out,local(outer["stderr_path"],exists=False).open("xb",buffering=0) as err:
        result=subprocess.run(command,stdout=out,stderr=err)
    actual=dict(**outer,status=result.returncode,stdout=local(outer["stdout_path"]).read_text(),stderr=local(outer["stderr_path"]).read_text(),
                programmes_after=programs(),native_stdout=local(row["stdout_path"]).read_text() if Path(row["stdout_path"]).exists() else None,
                native_stderr=local(row["stderr_path"]).read_text() if Path(row["stderr_path"]).exists() else None)
    save(filename(attempt,name,"-guard-actual.json"),actual)
    print("original guarded reader",name,"status",result.returncode,flush=True)
    need(type(result.returncode) is int and result.returncode==0 and actual["programmes"]==actual["programmes_after"]==programs(),
         "actual successful unchanged original guarded reader; every interrupted attempt is non-success")
    qualify(load(filename(attempt,name,"-actual.json")),spec)

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--child",action="store_true");parser.add_argument("--attempt",required=True);parser.add_argument("--name",required=True)
    args=parser.parse_args()
    (child if args.child else execute)(args.attempt,args.name)
