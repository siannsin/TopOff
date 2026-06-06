# Security Policy

## Reporting a vulnerability

If you have found a security issue in TopOff, I would genuinely appreciate hearing about it privately before it is shared publicly.

Please email **security@malsahlabs.com** with the details. Starting the subject line with `TopOff Security` helps make sure it does not get lost.

Helpful things to include, if you have them:

- A description of the issue and why you believe it is a security concern
- The version of TopOff and the version of macOS you are running
- Steps to reproduce, or a small proof of concept
- Anything you think I should know about the potential impact

You do not need to have all of this worked out. A short note pointing me in the right direction is far better than staying quiet.

## What to expect

TopOff is maintained by a small team, so I cannot promise enterprise response times, but I take security reports seriously:

- I aim to acknowledge your report within **3 business days**.
- I will keep you informed as I investigate and work on a fix.
- Once a fix ships, I am glad to credit you in the release notes, or to keep you anonymous if you would rather.

I ask that you give me a reasonable amount of time to release a fix before disclosing the issue publicly. I am committed to coordinated disclosure and will not pursue legal action against good-faith security research.

## Supported versions

Security fixes are issued for the latest published release of TopOff. I recommend always running the most recent version.

| Version | Supported |
|---------|-----------|
| 2.0 (latest) | Yes |
| < 2.0 | No |

## Scope

TopOff is a lightweight menu bar front end for [Homebrew](https://brew.sh). When you run an update, TopOff launches Homebrew as a separate process, and Homebrew does the actual work of downloading and installing packages.

A few things therefore fall outside TopOff's control:

- Vulnerabilities in Homebrew itself, or in the individual formulae and casks it installs, are best reported to those projects directly.
- Network connections you may see attributed to TopOff in a firewall are usually Homebrew's child process, not TopOff. The Privacy & Network Connections section of the [README](README.md) explains this in more detail.

Anything in TopOff's own code, its signing and update mechanism, or how it handles your data is squarely in scope, and I want to hear about it.

Thank you for helping keep TopOff and the people who use it safe.

— Thomas Haslam, Malsah Labs LLC
