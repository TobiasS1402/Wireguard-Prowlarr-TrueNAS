# Manual PIA VPN Connections for TrueNAS Jails

### This is a FreeBSD/FreeNAS fork of the original Linux scripts at https://github.com/pia-foss/manual-connections.  
Fork Notes:
1. The scripts are set up to work via either OpenVPN or Wireguard.  Comment out the one you don't use in `run_setup.sh`. 
2. If you clone this repository, I suggest you change the directory name to `/pia` because that's the directory name I used. 
3. `run_setup.sh` is the script you call to start the whole process.  It calls the following script and so on.  If you're using port forwarding, `port_forwarding.sh` and `refresh_pia_port.sh` are the last scripts called.  The port needs to be refreshed about every 15 minutes.  I separated out the code in the latter script so it could be called by a cron job inside the jail.  That way the script doesn't need to be left running in a tmux session or something.  Cron should look like `*/15 * * * * /pia/refresh_pia_port.sh > /pia-info/refresh.log 2>&1` and run as `root`.  The output will be in `/pia-info/refresh.log`.
4. I changed `run_setup.sh` from a question-answer format to simply a settings/config file for the process.  Just edit to your desired settings.  PIA username and password are handled as an external file `/pia-info/pia_creds.txt` in the old style: first line user name, second line password.  If you don't want such a file sitting on your server, you can get the question-answer code from the Linux script and change that part.
5. In `port_forwarding.sh`, I added a transmission command to send the port number to transmission-rpc.  For this to work, transmission should be running before you start the scripts.  (OpenVPN should NOT be running, as the scripts configure and start it. `service openvpn stop`)
6. If you have trouble, carefully read the output to see where it failed.  I added a printed header to each script when it starts so you can see where you are (not `openvpn_up.sh` because it is run by OpenVPN).  Should OpenVPN fail to start, I added a command to print `/pia-info/debug_info` to screen so you can see what was going on with OpenVPN.  The scripts also store a bunch of other stuff in `/pia-info`. 
7. At least for OpenVPN, the network interface used is tun0.  If you start run_setup.sh interactively, a later script will check for tun0 and offer to kill the openvpn process that started it.  Otherwise, it will create another tun# and report everything is great, but you won't actually have your open port in transmission.
8. I start `run_setup.sh` with an @reboot cron job inside the jail so it starts when the jail starts: `@reboot cd /pia && /pia/run_setup.sh > /pia-info/startup.log 2>&1`.  This puts all the output in a log in `/pia-info`.  If the jail just started, there shouldn't be any openvpn process or tun0, so that shouldn't be a problem.

End of Fork Notes

This repository contains documentation on how to create native WireGuard and OpenVPN connections to Private Internet Access' (PIA) __NextGen network__, and also on how to enable Port Forwarding in case you require this feature. You will find a lot of information below. However if you prefer quick test, here is the __TL/DR__:

```
git clone https://github.com/TobiasS1402/manual-connections-qbittorrent.git
cd manual-connections-qbittorrent # I changed the directory name to pia.
./run_setup.sh
```

### IPFW notes
For security purposes there is a ipfw script and config in /ipfw/, installing this and filling it with your subnets will ensure that qbittorrent can't download torrents via your ip address.

### Dependencies

In order for the scripts to work (probably even if you do a manual setup), you will need the following packages:
 * `bash`
 * `curl`
 * `jq`
 * (only for WireGuard) `wireguard` kernel module
 * (only for OpenVPN) `openvpn`
 * (only for port forwarding) `base64`
 * (when using Qbittorrent) `qbittorrent-nox`
 * `git`

### Disclaimers

 * Port Forwarding is disabled on server-side in the United States.
 * These scripts do not enforce IPv6 or DNS settings, so that you have the freedom to configure your setup the way you desire it to work. This means you should have good understanding of VPN and cybersecurity in order to properly configure your setup.
 * For battle-tested security, please use the official PIA App, as it was designed to protect you in all scenarios.
 * This repo is really fresh at this moment, so please take into consideration the fact that you will probably be one of the first users that use the scripts.

## PIA Port Forwarding

The PIA Port Forwarding service (a.k.a. PF) allows you run services on your own devices, and expose them to the internet by using the PIA VPN Network. The easiest way to set this up is by using a native PIA aplication. In case you require port forwarding on native clients, please follow this documentation in order to enable port forwarding for your VPN connection.

This service can be used only AFTER establishing a VPN connection.

## Automated setup of VPN and/or PF

In order to help you use VPN services and PF on any device, we have prepared a few bash scripts that should help you through the process of setting everything up. The scripts also contain a lot of comments, just in case you require detailed information regarding how the technology works. The functionality is controlled via environment variables, so that you have an easy time automating your setup.

Here is a list of scripts you could find useful:
 * [Get the best region and a token](get_region_and_token.sh): This script helps you to get the best region and also to get a token for VPN authentication. Adding your PIA credentials to env vars `PIA_USER` and `PIA_PASS` will allow the script to also get a VPN token. The script can also trigger the WireGuard script to create a connection, if you specify `PIA_AUTOCONNECT=wireguard` or `PIA_AUTOCONNECT=openvpn_udp_standard`
 * [Connect to WireGuard](connect_to_wireguard_with_token.sh): This script allows you to connect to the VPN server via WireGuard.
 * [Connect to OpenVPN](connect_to_openvpn_with_token.sh): This script allows you to connect to the VPN server via OpenVPN.
 * [Enable Port Forwarding](port_forwarding.sh): Enables you to add Port Forwarding to an existing VPN connection. Adding the environment variable `PIA_PF=true` to any of the previous scripts will also trigger this script.

## Manual setup of PF

To use port forwarding on the NextGen network, first of all establish a connection with your favorite protocol. After this, you will need to find the private IP of the gateway you are connected to. In case you are WireGuard, the gateway will be part of the JSON response you get from the server, as you can see in the [bash script](https://github.com/pia-foss/manual-connections/blob/master/wireguard_and_pf.sh#L119). In case you are using OpenVPN, you can find the gateway by checking the routing table with `ip route s t all`.

After connecting and finding out what the gateway is, get your payload and your signature by calling `getSignature` via HTTPS on port 19999. You will have to add your token as a GET var to prove you actually have an active account.

Example:
```bash
bash-5.0# curl -k "https://10.4.128.1:19999/getSignature?token=$TOKEN"
{
    "status": "OK",
    "payload": "eyJ0b2tlbiI6Inh4eHh4eHh4eCIsInBvcnQiOjQ3MDQ3LCJjcmVhdGVkX2F0IjoiMjAyMC0wNC0zMFQyMjozMzo0NC4xMTQzNjk5MDZaIn0=",
    "signature": "a40Tf4OrVECzEpi5kkr1x5vR0DEimjCYJU9QwREDpLM+cdaJMBUcwFoemSuJlxjksncsrvIgRdZc0te4BUL6BA=="
}
```

The payload can be decoded with base64 to see your information:
```bash
$ echo eyJ0b2tlbiI6Inh4eHh4eHh4eCIsInBvcnQiOjQ3MDQ3LCJjcmVhdGVkX2F0IjoiMjAyMC0wNC0zMFQyMjozMzo0NC4xMTQzNjk5MDZaIn0= | base64 -d | jq 
{
  "token": "xxxxxxxxx",
  "port": 47047,
  "expires_at": "2020-06-30T22:33:44.114369906Z"
}
```
This is where you can also see the port you received. Please consider `expires_at` as your request will fail if the token is too old. All ports currently expire after 2 months.

Use the payload and the signature to bind the port on any server you desire. This is also done by curling the gateway of the VPN server you are connected to.
```bash
bash-5.0# curl -sGk --data-urlencode "payload=${payload}" --data-urlencode "signature=${signature}" https://10.4.128.1:19999/bindPort
{
    "status": "OK",
    "message": "port scheduled for add"
}
bash-5.0# 
```

Call __/bindPort__ every 15 minutes, or the port will be deleted!

### Testing your new PF

To test that it works, you can tcpdump on the port you received:

```
bash-5.0# tcpdump -ni any port 47047
```

After that, use curl on the IP of the traffic server and the port specified in the payload which in our case is `47047`:
```bash
$ curl "http://178.162.208.237:47047"
```

and you should see the traffic in your tcpdump:
```
bash-5.0# tcpdump -ni any port 47047
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes
22:44:01.510804 IP 81.180.227.170.33884 > 10.4.143.34.47047: Flags [S], seq 906854496, win 64860, options [mss 1380,sackOK,TS val 2608022390 ecr 0,nop,wscale 7], length 0
22:44:01.510895 IP 10.4.143.34.47047 > 81.180.227.170.33884: Flags [R.], seq 0, ack 906854497, win 0, length 0
```

## License
This project is licensed under the [MIT (Expat) license](https://choosealicense.com/licenses/mit/), which can be found [here](/LICENSE).
