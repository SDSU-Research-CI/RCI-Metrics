# Kubernetes Manifest Usage

This folder contains the Kubernetes manifests for running the RCI Metrics
container as a batch job and retrieving its output afterward.

The main job definition is [metrics_manifest.yml](/Users/heli/Desktop/Scripts/RCI-Metrics/manifests/metrics_manifest.yml).
It runs the metrics container, mounts a persistent volume for output, and
mounts a Kubernetes secret that provides the runtime config file.

## Files In This Folder

- `metrics_manifest.yml`: Kubernetes `Job` that runs the metrics workload.
- `metrics_pvc.yml`: PersistentVolumeClaim used to store output files.
- `metrics_config_secret.yml`: Secret that provides `/app/secret-config/config.yaml`
  inside the container.
- `pvc_access.yaml`: Temporary debug pod used to inspect or copy files from the PVC
  after the job finishes.

## 1. Build And Publish The Container Image

Use the Docker setup in [`docker/`](../docker/README.md) to build the image from the
repository root:

```bash
docker build -t <your-image>:<tag> -f docker/Dockerfile .
```

If you need to publish the image so your cluster can pull it:

```bash
docker push <your-image>:<tag>
```

Then update the `image:` field in `metrics_manifest.yml` if you are not using the
default image:

```yaml
containers:
  - name: metrics
    image: <your-image>:<tag>
```

## 2. Choose The Config To Run

The job expects this environment variable:

```yaml
env:
  - name: CONFIG_FILE
    value: /app/secret-config/config.yaml
```

That means the container always reads the config file from the secret mounted at
`/app/secret-config/config.yaml`.

To switch configs, edit `metrics_config_secret.yml` and replace the contents under
`stringData.config.yaml` with any config you want to run from the [`configs/`](../configs)
folder, such as:

- `configs/monthly.yaml`
- `configs/tidesplit.yaml`
- `configs/usedcapacity.yaml`
- `configs/ytdcpu.yaml`

In other words, `metrics_config_secret.yml` is the Kubernetes-wrapped version of
whichever config you want the job to use.

## 3. Create The Storage And Config

Apply the PVC and config secret first:

```bash
kubectl apply -f manifests/metrics_pvc.yml
kubectl apply -f manifests/metrics_config_secret.yml
```

If you update the config later, re-apply the secret before rerunning the job:

```bash
kubectl apply -f manifests/metrics_config_secret.yml
```

## 4. Run The Metrics Job

Start the batch job:

```bash
kubectl apply -f manifests/metrics_manifest.yml
```

Check status:

```bash
kubectl get jobs
kubectl get pods
kubectl logs job/metrics-job
```

The job mounts the PVC at `/app/io/`. Output will be written there based on the
config's `saving.base-path` value. In the current example config, output goes under:

```text
/app/io/tidesplit_latest
```

## 5. Access Output After The Job Completes

After the job finishes, create the helper pod in `pvc_access.yaml` so you can mount
the same PVC and inspect or copy the generated files:

```bash
kubectl apply -f manifests/pvc_access.yaml
kubectl get pod pvc-debug
```

Open a shell in the helper pod:

```bash
kubectl exec -it pvc-debug -- sh
```

Inside the pod, the PVC is mounted at:

```text
/app/io/
```

You can inspect the generated output from there, for example:

```bash
ls -R /app/io
```

To download the output locally, use `kubectl cp` from your machine:

```bash
kubectl cp pvc-debug:/app/io ./metrics-output
```

## 6. Clean Up

Delete the job and helper pod when you are done:

```bash
kubectl delete -f manifests/metrics_manifest.yml
kubectl delete -f manifests/pvc_access.yaml
```

If you also want to remove the config secret or PVC:

```bash
kubectl delete -f manifests/metrics_config_secret.yml
kubectl delete -f manifests/metrics_pvc.yml
```

Be careful deleting the PVC, since that also removes the stored output for this
workflow.

## Notes

- The repo currently names the files `metrics_manifest.yml` and
  `metrics_config_secret.yml`, even if you refer to them as `.yaml`.
- `metrics_manifest.yml` already expects the config file path
  `/app/secret-config/config.yaml`, so the secret should keep that filename unless
  you also update the job manifest.
- If you rerun the job with the same name, you may need to delete the old job first:

```bash
kubectl delete job metrics-job
kubectl apply -f manifests/metrics_manifest.yml
```
