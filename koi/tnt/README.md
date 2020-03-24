INSTALL TNT AND EXPOSE USING ISTIO

1. Create namespace tnt with label istio-injection: enabled
    - $ kubectl create ns-tnt

    - ns-tnt:
    <pre><code>
    kind: Namespace
    apiVersion: v1
    metadata:
        name: tnt
        labels:
            istio-injection: enabled
    </code></pre>

2. Copy istio-ca-root-cert
    - $ kubectl get configmap istio-ca-root-cert -n default -o yaml | sed 's/default/tnt/g' | kubectl -n tnt create -f -

3. Create/copy image pull secret (not necessary if pulling image from public registry) - In this example the repository is the IBM Cloud Repository and we are copying a existing secret
    - $ kubectl get secret default-de-icr-io -n default -o yaml | sed 's/default/tnt/g' | kubectl -n tnt create -f -

4. Deploy the app - is using tnt-de-icr-io as pullingImageSecret, change yaml if necessary
    - $ kubectl create -f deploy-tnt.yml

    - deploy-tnt.yml:
    <pre><code>
    apiVersion: v1
    kind: Service
    metadata:
    name: tnt-frontend-service
    namespace: tnt
    labels:
        app: tnt-frontend
        service: tnt-frontend
    spec:
    ports:
    - port: 80
        name: http
    selector:
        app: tnt-frontend
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: tnt-frontend-app
    namespace: tnt
    labels:
        app: tnt-frontend
    spec:
    replicas: 1
    selector:
        matchLabels:
        app: tnt-frontend
    template:
        metadata:
        labels:
            app: tnt-frontend
        spec:
        containers:
        - name: tnt-frontend-app
            image: de.icr.io/airc-registry/tnt-frontend:1.0.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 80
        imagePullSecrets:
            -  name: tnt-de-icr-io
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: tnt-backend-service
    namespace: tnt
    labels:
        app: tnt-backend
        service: tnt-backend
    spec:
    ports:
    - port: 8080
        name: http
    selector:
        app: tnt-backend
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: tnt-backend-app
    namespace: tnt
    labels:
        app: tnt-backend
    spec:
    replicas: 1
    selector:
        matchLabels:
        app: tnt-backend
    template:
        metadata:
        labels:
            app: tnt-backend
        spec:
        containers:
        - env:
            - name: ADM_URL
            value: http://localhost
            - name: ALFRESCO_APP
            value: PROD/TNT
            - name: ALFRESCO_PASSWORD
            value: admin
            - name: ALFRESCO_URL
            value: http://localhost
            - name: ALFRESCO_USERNAME
            value: admin
            - name: DAS_EMAIL
            value: apoio.das@airc.pt
            - name: DATABASE_PASSWORD
            value: tnt
            - name: DATABASE_URL
            value: jdbc:postgresql://pg-ha-postgresql-ha-pgpool.database.svc.cluster.local:5432/tnt?connectTimeout=60
            - name: DATABASE_USERNAME
            value: tnt
            - name: KEYCLOAK_PASSWORD
            value: admin
            - name: KEYCLOAK_REALM
            value: erp-airc-saas
            - name: KEYCLOAK_URL
            value: http://localhost
            - name: KEYCLOAK_USER
            value: admin
            name: tnt-backend-app
            image: de.icr.io/airc-registry/tnt-backend:1.0.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 8080
        imagePullSecrets:
            -  name: tnt-de-icr-io
    </code></pre>

5. Create VirtualService to expose app outside the cluster
    - $ kubectl create gateway-tnt.yml

    - gateway-tnt.yml:
    <pre><code>
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
    name: tnt-gateway
    namespace: tnt
    spec:
    selector:
        istio: ingressgateway # use istio default controller
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
        hosts:
        - "29a53d09-eu-de.lb.appdomain.cloud"
    - port:
        number: 80
        name: tcp
        protocol: TCP
        hosts:
        - "29a53d09-eu-de.lb.appdomain.cloud"
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
    name: tnt
    namespace: tnt
    spec:
    hosts:
    - "29a53d09-eu-de.lb.appdomain.cloud"
    gateways:
    - tnt-gateway
    http:
    - match:
        - uri:
            prefix: /api/v1/tnt
        route:
        - destination:
            host: tnt-backend-service
            port:
            number: 8080
    - match:
        - uri:
            prefix: /tnt/
          rewrite:
            uri: " "
        - uri:
            prefix: /tnt
          rewrite:
            uri: /
        route:
        - destination:
            host: tnt-frontend-service.tnt.svc.cluster.local
            port:
            number: 80
    </code></pre>
