#!/bin/bash
# 新番組用の k8s マニフェスト雛形を生成する。
#
# 使い方:
#   ./scripts/new-program.sh <name> <STATION_ID> <start_hhmm> <end_hhmm> "<cron>" <weekday>
#
# 例（毎週金曜深夜1:00-3:00 ニッポン放送）:
#   ./scripts/new-program.sh ann1-friday LFR 0100 0300 "0 4 * * 5" FRI
#
# 引数:
#   name         ディレクトリ名（英数字とハイフン）
#   STATION_ID   radiko 局ID（例: LFR, TBS, QRR）
#   start_hhmm   放送開始時刻 HHMM（例: 0300）
#   end_hhmm     放送終了時刻 HHMM（例: 0430）
#   cron         cron スケジュール（番組終了後に実行。ダブルクォートで囲む）
#   weekday      番組曜日（例: MON, TUE, WED, THU, FRI, SAT, SUN）
#
# コーナー設定は生成後に configmap.yaml の CORNERS を編集すること

set -e

NAME=${1:?  "引数1 <name> が必要です"}
STATION=${2:?"引数2 <STATION_ID> が必要です"}
START=${3:?  "引数3 <start_hhmm> が必要です"}
END=${4:?    "引数4 <end_hhmm> が必要です"}
CRON=${5:?   "引数5 <cron> が必要です"}
WEEKDAY=${6:?"引数6 <weekday> が必要です"}
START_TIME="${START:0:2}:${START:2:2}"
END_TIME="${END:0:2}:${END:2:2}"

DEST="$(dirname "$0")/../programs/${NAME}"

if [ -d "${DEST}" ]; then
  echo "ERROR: ${DEST} は既に存在します"
  exit 1
fi

mkdir -p "${DEST}"

cat > "${DEST}/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${NAME}-config
  namespace: radio-recorder
data:
  STATION_ID: "${STATION}"
  PROGRAM_WEEKDAY: "${WEEKDAY}"
  PROGRAM_START_TIME: "${START_TIME}"
  PROGRAM_END_TIME: "${END_TIME}"
  PROGRAM_TIMEZONE: "Asia/Tokyo"
  # コーナーを追加する場合は配列に要素を追加する
  CORNERS: |
    [
      {
        "name": "コーナー名（シート名になる）",
        "start_keywords": ["開始キーワード1", "開始キーワード2"],
        "end_keywords": ["終了キーワード1"],
        "description": "コーナーの説明（省略可）"
      }
    ]
  OUTPUT_DIR: "/data/radio"
  GOOGLE_CREDENTIALS: "/app/credentials.json"
EOF

cat > "${DEST}/cronjob.yaml" <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ${NAME}
  namespace: radio-recorder
  labels:
    app: radio-recorder
spec:
  schedule: "${CRON}"
  timeZone: "Asia/Tokyo"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      activeDeadlineSeconds: 9000
      template:
        metadata:
          labels:
            app: radio-recorder
        spec:
          restartPolicy: Never
          containers:
            - name: radio-recorder
              image: radio-recorder:latest
              imagePullPolicy: Never
              envFrom:
                - configMapRef:
                    name: ${NAME}-config
                - secretRef:
                    name: radio-recorder-secret
              volumeMounts:
                - name: radio-data
                  mountPath: /data
                - name: google-credentials
                  mountPath: /app/credentials.json
                  subPath: credentials.json
                  readOnly: true
                - name: tmp
                  mountPath: /tmp
              resources:
                requests:
                  cpu: 100m
                  memory: 256Mi
                limits:
                  cpu: 500m
                  memory: 512Mi
          volumes:
            - name: radio-data
              persistentVolumeClaim:
                claimName: radio-data-pvc
            - name: google-credentials
              secret:
                secretName: google-credentials
            - name: tmp
              emptyDir: {}
EOF

echo "==> 生成完了: ${DEST}"
echo "    次のステップ:"
echo "    1. ${DEST}/configmap.yaml の CORNERS を編集（コーナー名・キーワード）"
echo "    2. kubectl apply -f ${DEST}/"
