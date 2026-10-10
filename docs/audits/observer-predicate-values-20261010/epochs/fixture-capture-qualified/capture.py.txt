"""Retain complete actual public fixture output without consulting old traces."""
import subprocess
from common import BASE, load, need, pin, save


def main():
    plan=load('fixture-plan-qualified.json'); driver=BASE/'native-qualified.pl'
    need(pin(driver.read_bytes()) == plan['driver'],'preselected complete driver')
    need(not (BASE/'native-qualified.json').exists(),'one fresh source-neutral native capture')
    result=subprocess.run(['perl',str(driver)],capture_output=True,text=True)
    save('native-qualified.json',dict(command=['perl',str(driver)],status=result.returncode,stdout=result.stdout,stderr=result.stderr,
        plan=pin((BASE/'fixture-plan-qualified.json').read_bytes()),driver=plan['driver']))
    need(result.returncode == 0 and not result.stderr,'complete current public fixture execution')
    print('PASS complete current source-neutral public fixture capture retained; no original execution recapture.')


if __name__ == '__main__': main()
