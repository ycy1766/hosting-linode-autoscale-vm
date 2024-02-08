# hosting-linode-autoscale-vm

Prometheus-am-executor 기반으로 Linode 환경에서 Instnace Auto-Scale 구성을 위한 테스트 파일 입니다. 
Prometheus 로 수집된 Metric 임계치 상승 시 prometheus-am-executor 의하여 Jenkinks Hook 을 보내고 , 응답 코드에 따라 Scale 을 Terraform 에 의하여 조정 합니다. 

- [reference-architecture](https://www.linode.com/docs/reference-architecture/auto-scaling-prometheus/)





