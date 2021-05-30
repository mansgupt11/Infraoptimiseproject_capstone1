Testing for netpol access 

root@ip-172-31-6-192:~# kubectl get po -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP          NODE              NOMINATED NODE   READINESS GATES
be-postgres   1/1     Running   0          21m   10.32.0.6   ip-172-31-5-185   <none>           <none>
fe-nginx      1/1     Running   0          21m   10.32.0.5   ip-172-31-5-185   <none>           <none>
root@ip-172-31-6-192:~# kubectl run busybox1 --rm -ti --image=busybox -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # wget --spider --timeout=1 nginx
Connecting to nginx (10.102.183.62:80)
wget: download timed out
/ # wget --spider --timeout=1 10.32.0.5
Connecting to 10.32.0.5 (10.32.0.5:80)
remote file exists
/ # wget --spider --timeout=10.32.0.6
wget: invalid number '10.32.0.6'
/ # exit
Session ended, resume using 'kubectl attach busybox1 -c busybox1 -i -t' command when the pod is running
pod "busybox1" deleted
root@ip-172-31-6-192:~# kubectl run busybox1 --rm -ti --image=busybox -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # ping 10.32.0.5
PING 10.32.0.5 (10.32.0.5): 56 data bytes
64 bytes from 10.32.0.5: seq=0 ttl=64 time=0.156 ms
64 bytes from 10.32.0.5: seq=1 ttl=64 time=0.083 ms
64 bytes from 10.32.0.5: seq=2 ttl=64 time=0.067 ms
^C
--- 10.32.0.5 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.067/0.102/0.156 ms
/ # ping 10.32.0.6
PING 10.32.0.6 (10.32.0.6): 56 data bytes
^C
--- 10.32.0.6 ping statistics ---
6 packets transmitted, 0 packets received, 100% packet loss
/ #
