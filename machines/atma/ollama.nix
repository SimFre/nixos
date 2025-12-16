{ pkgs, ... }:
{
  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = true;
    #acceleration = "cuda";
    host = "[::]";
    port = 11434;
  };
  services = {
    open-webui = {
      enable = true;
    };
  };
}

#{ pkgs, ... }:
#{#
#
#  # Add to your NixOS configuration
#  environment.systemPackages = with pkgs; [
#    docker
#  ];#
#
#  # Enable Docker
#  services.docker.enable = true;#
#
#}

# docker run - d - -name ollama - p "11434:11434" ollama/ollama
# curl http://localhost:11434/api/pull -d '{"name": "llama3"}'

#curl http://localhost:11434/api/generate -d '{
#  "model": "llama3",
#  "prompt": "What packages should I install on FreeBSD to run Tauri?"
#}'

## Create a Simple API Wrapper (Optional)

# from fastapi import FastAPI, Request
# import requests
#
# app = FastAPI()
#
# @app.post("/ask")
# async def ask(request: Request):
#     data = await request.json()
#     prompt = data["prompt"]
#     response = requests.post("http://localhost:11434/api/generate", json={
#         "model": "llama3",
#         "prompt": prompt
#     })
#     return response.json()
