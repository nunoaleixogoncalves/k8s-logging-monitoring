INSTALL EFK STACK WITH HELM

Helm repos:

    - https://helm.elastic.co # https://github.com/elastic/helm-charts (elasticsearch & kibana)
    - https://kiwigrid.github.io/ # https://github.com/kiwigrid/helm-charts (fluentd)
    
    Add repos to local helm and update
        $ helm repo add kiwigrid https://kiwigrid.github.io
        $ helm repo add elastic https://helm.elastic.co
        $ helm repo update

Steps:

    1. Create namespace
        $ kubectl create -f logging/ns_logging.yaml

    2. Install helm charts
        2.1 Install elasticsearch
            $ helm install elasticsearch-helm --namespace logging -f elasticsearch-values.yml elastic/elasticsearch

            -> for more info about the chart and configuration of elasticsearch-values.yml see https://github.com/elastic/helm-charts/tree/master/elasticsearch

        2.2 Install kibana
            $ helm install kibana-helm --namespace logging -f elastic/kibana

            -> for more info about the chart see https://github.com/elastic/helm-charts/tree/master/kibana

        2.3 Install fluentd
            $ helm install fluentd-helm --namespace logging -f fluentd-values.yml kiwigrid/fluentd-elasticsearch

            -> for more info about the chart and configuration of fluentd-values.yml see https://github.com/kiwigrid/helm-charts/tree/master/charts/fluentd-elasticsearch

    3. Access Kibana on localhost
        $ kubectl port-forward svc/kibana 5601 -n logging
        
        -> go to http://localhost:5601


INSTALL PROMETHEUS & GRAFANA HELM

Helm repos:

    Add repos to local helm and update
        $ helm repo add stable https://kubernetes-charts.storage.googleapis.com
        $ helm repo update

Steps:

    1. Create namespace
        $ kubectl create -f ns_monitoring.yml

    2. Install helm charts
        2.1 Install prometheus
            $ helm install prometheus stable/prometheus --namespace monitoring
        
        2.2 Install grafana
            2.2.1 Apply config grafana
                $ kubectl apply -f monitoring/grafana/config.yml
            
            2.2.2 Install grafana helm
                $ helm install grafana stable/grafana -f monitoring/grafana/values.yml --namespace monitoring 

            2.2.3 Get grafana password
                $ kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
        
            2.2.4 Access Grafana dashboard
                $ kubectl get pods --namespace=monitoring

                    Get name of grafana pod ex: grafana-7d84b55bf-km2fn  
                $ kubectl --namespace monitoring port-forward grafana-7d84b55bf-km2fn 3000
                    username: admin
                    password: result of step 2.2.3

            2.2.5 Add a dashboard
                
                Grafana has a long list of prebuilt dashboard here:
                https://grafana.com/dashboards
                
                1-> In the left hand menu, choose Dashboards > Manage > + Import
                2-> In the Grafana.com dashboard input, add the dashboard ID we want to use: 1860 and click Load
                3-> On the next screen select a name for your dashboard and select Prometheus as the datasource for it and click Import.
