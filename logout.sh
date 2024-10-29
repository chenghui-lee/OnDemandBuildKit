#!/bin/bash
ssh -o StrictHostKeychecking=no ec2-user@100.123.45.0 sudo tailscale logout
ssh -o StrictHostKeychecking=no ec2-user@100.123.46.0 sudo tailscale logout