#!/bin/bash

# Sätt sökvägen till din SSH-nyckel i keys/-mappen
MY_SSH="./keys/image-app-key.pem"

# 1. Skapa user-data skript för EC2 (Ansible-playbooken)
cat<<"EOF" > user-data.web.sh
#!/bin/bash
###########################################################
# Automatiserad uppsättning av AI-Bildgenerator
###########################################################
dnf -y update
dnf -y install ansible git-core

# Skapa Ansible Playbook lokalt på EC2-instansen
cat<<"EOA" > config-and-deploy.web.yml
- hosts: localhost
  become: true

  tasks:
    ### 1. Installera systempaket
    - name: Installera Nginx, Git, Python3 och Pip
      dnf:
        name:
          - nginx
          - git-core
          - python3
          - python3-pip
        state: latest
        update_cache: yes

    - name: Starta och aktivera Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    ### 2. Klona källkod & sätt upp Python-miljö
    - name: Klona AI-bildgeneratorn från GitHub
      git:
        repo: 'https://github.com/kevham89/ai-bildgenerator.git'
        dest: /var/www/ai-bildgenerator
        clone: yes
        update: yes

    - name: Skapa virtuell miljö och installera beroenden
      pip:
        requirements: /var/www/ai-bildgenerator/requirements.txt
        virtualenv: /var/www/ai-bildgenerator/venv
        virtualenv_command: python3 -m venv

    ### 3. Konfigurera .env med API-nyckel
    # ERSÄTT hf_din_riktiga_token_har NEDAN MED DIN RIKTIGA TOKEN
    - name: Skapa .env-fil för Hugging Face Token
      copy:
        dest: /var/www/ai-bildgenerator/.env
        content: |
          HUGGINGFACE_TOKEN=hf_din_riktiga_token_har
        owner: root
        group: root
        mode: '0600'

    ### 4. Skapa Systemd-tjänst för Flask via Gunicorn
    - name: Skapa Systemd-tjänst för Gunicorn
      copy:
        dest: /etc/systemd/system/bildgenerator.service
        content: |
          [Unit]
          Description=Gunicorn instance to serve AI Image Generator
          After=network.target

          [Service]
          User=root
          WorkingDirectory=/var/www/ai-bildgenerator
          Environment="PATH=/var/www/ai-bildgenerator/venv/bin"
          ExecStart=/var/www/ai-bildgenerator/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:8000 app:app

          [Install]
          WantedBy=multi-user.target

    - name: Ladda om systemd och starta bildgenerator-tjänsten
      systemd:
        name: bildgenerator
        state: restarted
        enabled: yes
        daemon_reload: yes

    ### 5. Konfigurera Nginx Reverse Proxy (Port 80 -> Port 8000)
    - name: Skapa Nginx-konfiguration
      copy:
        dest: /etc/nginx/conf.d/bildgenerator.conf
        content: |
          server {
              listen 80;
              server_name _;

              location / {
                  proxy_pass http://127.0.0.1:8000;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              }
          }

    - name: Starta om Nginx
      service:
        name: nginx
        state: restarted
EOA

# Kör Ansible Playbook direkt på servern
ansible-playbook -v config-and-deploy.web.yml
EOF

# 2. Kör Terraform för att bygga/uppdatera infrastrukturen
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"

# 3. Hämta EC2-DNS och följ loggen via SSH
export MY_EC2=$(terraform output -json | jq -r .ec2_public_dns_name.value)

echo "Kopplar upp mot EC2 ($MY_EC2) for att visa installationsstatus..."
ssh -i $MY_SSH ec2-user@$MY_EC2 sudo tail -f /var/log/cloud-init-output.log