from kubernetes import client, config

config.load_kube_config()
v1 = client.CoreV1Api()

pods = v1.list_namespaced_pod(namespace="kube-system", field_selector="status.phase=Running")

for pod in pods.items:
    print(pod.metadata.name)