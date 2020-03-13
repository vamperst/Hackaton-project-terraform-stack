# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

curl -sSL https://get.docker.com/ | sudo sh
sudo usermod -aG docker ubuntu
sudo apt install awscli -y


login=$(aws ecr get-login --region=us-east-1)
login=$(echo $login | sed 's/-e none/ /g' | tee)
echo $login | bash

TAG=$(aws ecr describe-images --region=us-east-1 --output json --repository-name hackathon-app --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --output=text)
dockerImage=${ECR_REGISTRY}:$TAG
docker pull $dockerImage

docker run -d -p 80:80 $dockerImage

echo "DONE!!"
