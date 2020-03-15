INSTALL EFK STACK WITH HELM

Helm repos:

    - https://helm.elastic.co # https://github.com/elastic/helm-charts (elasticsearch & kibana)
    - https://kiwigrid.github.io/ # https://github.com/kiwigrid/helm-charts (fluentd)

Steps:

    1. Add repos to local helm
        $ helm repo add kiwigrid https://kiwigrid.github.io
        $ helm repo add elastic https://helm.elastic.co

    2. Create namespace
        .../efk$ kubectl create -f ns_kube-logging.yaml

    3. Install helm charts
        3.1 Install elasticsearch
            .../efk$ helm install elasticsearch-helm --namespace kube-logging -f elasticsearch-values.yml elastic/elasticsearch

            for more info about the chart and configuration of elasticsearch-values.yml see https://github.com/elastic/helm-charts/tree/master/elasticsearch

        3.2 Install kibana
            .../efk$ helm install kibana-helm --namespace kube-logging -f elastic/kibana

            for more info about the chart see https://github.com/elastic/helm-charts/tree/master/kibana

        3.3 Install fluentd
            .../efk$ helm install fluentd-helm --namespace kube-logging -f fluentd-values.yml kiwigrid/fluentd-elasticsearch

            for more info about the chart and configuration of fluentd-values.yml see https://github.com/kiwigrid/helm-charts/tree/master/charts/fluentd-elasticsearch

    4. Access Kibana on localhost
        $ kubectl port-forward svc/kibana 5601 -n kube-logging
        go to http://localhost:5601

