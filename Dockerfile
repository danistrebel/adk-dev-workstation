# Customize the default cloud workstation image
FROM europe-west1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# Add Terraform archive
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install packages
RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt update && sudo apt install -y zsh python3-venv libpq-dev terraform shellcheck google-cloud-cli-cloud-run-proxy \
 && apt-get clean

# Install ZSH plugins
ENV ZSH=/opt/workstation/zsh

RUN git clone https://github.com/zsh-users/zsh-autosuggestions /opt/workstation/zsh/plugins/zsh-autosuggestions \
  && git clone https://github.com/zdharma-zmirror/fast-syntax-highlighting.git /opt/workstation/zsh/plugins/fast-syntax-highlighting \
  && git clone https://github.com/zsh-users/zsh-completions.git /opt/workstation/zsh/plugins/zsh-completions \
  && git clone https://github.com/spaceship-prompt/spaceship-prompt.git  /opt/workstation/zsh/themes/spaceship

# Install Code OSS extensions
RUN echo "https://open-vsx.org/api/ms-python/python" >> /tmp/extensions.txt \
 && echo "https://open-vsx.org/api/golang/go" >> /tmp/extensions.txt \
 && echo "https://open-vsx.org/api/vscode-icons-team/vscode-icons" >> /tmp/extensions.txt \
 && echo "https://open-vsx.org/api/google/gemini-cli-vscode-ide-companion" >> /tmp/extensions.txt \
 && while IFS= read -r extension_url; do \
    extension_name=$(echo "$extension_url" | sed -E 's#.*/([^/]+)/[^/]+$#\1#'); \
    wget -O "$extension_name.vsix" $(curl -q "$extension_url" | jq -r '.files.download'); \
    unzip "$extension_name.vsix" "extension/*"; \
    mv extension /opt/code-oss/extensions/"$extension_name"; \
    rm "$extension_name.vsix"; \
  done < /tmp/extensions.txt
RUN rm /tmp/extensions.txt

# install global NPM Modules
RUN npm install -g @google/gemini-cli

# install pip
RUN pip install uv google-adk --break-system-packages

# Runtime customization scripts
COPY startup-scripts/ /etc/workstation-startup.d/
RUN chmod +x /etc/workstation-startup.d/*
