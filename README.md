# TimeInjector
Time injector is a CVE-2018-14714 exploitation script in bash



To tell if the target is vulnerable, the script works by first checking if the target is accessible and if it can establish a login session.

After that, it checks for the existence of specific pages and performs a time-based injection to see if the system is vulnerable to remote code execution (RCE).

If the system responds slower when executing a command (like sleep 3), it indicates the target may be vulnerable.

This happens because the server is taking more time to process the injected command, and that delay confirms the vulnerability.

The exploit works by sending a specially crafted payload to the target that causes the system to run commands in an unintended manner, typically allowing command execution or information leakage.

The key part of detecting vulnerability is the response time delay, which shows the target is executing commands based on user input, confirming that an RCE vulnerability exists.
