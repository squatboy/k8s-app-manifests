# RBAC 정책 문서

## 개요
이 디렉토리는 Staging과 Production 환경의 RBAC(Role-Based Access Control) 정책을 정의함. (2025-10-31 수정)

## 팀별 권한 구조

### 개발팀 (dev-team)

#### Staging 환경
- **권한**: 배포, 리소스 생성·조회·수정 가능
- **제한사항**:
  - ❌ Secret 생성/수정/삭제 불가 (읽기만 가능)
  - ❌ SealedSecret 생성/수정/삭제 불가 (읽기만 가능)
  - ❌ 리소스 삭제 권한 없음
- **허용된 작업**:
  - ✅ Deployment, Rollout 배포
  - ✅ Service, Ingress 생성/수정
  - ✅ ConfigMap 관리
  - ✅ Pod 로그 확인 및 exec
  - ✅ ArgoCD Application Sync

#### Production 환경
- **권한**: 읽기 전용 (Read-Only)
- **허용된 작업**:
  - ✅ 모든 리소스 조회
  - ✅ Pod 로그 확인
  - ✅ ArgoCD Application Sync (배포 트리거)
- **제한사항**:
  - ❌ 리소스 생성/수정/삭제 불가

### 운영팀 (ops-team)

#### Staging/Production 환경 공통
- **권한**: 전체 관리 권한
- **허용된 작업**:
  - ✅ 모든 리소스 CRUD (생성/조회/수정/삭제)
  - ✅ Secret 관리
  - ✅ 네임스페이스 관리
  - ✅ RBAC 정책 관리
  - ✅ ArgoCD 전체 관리

## 파일 구조

```
manifests/rbac/
├── staging/
│   ├── serviceaccount-dev-team.yaml     # 개발팀 ServiceAccount
│   ├── serviceaccount-ops-team.yaml     # 운영팀 ServiceAccount
│   ├── role-dev-team.yaml               # 개발팀 권한 정의
│   ├── role-ops-team.yaml               # 운영팀 권한 정의
│   ├── rolebinding-dev-team.yaml        # 개발팀 권한 바인딩
│   └── rolebinding-ops-team.yaml        # 운영팀 권한 바인딩
├── production/
│   ├── serviceaccount-dev-team.yaml     # 개발팀 ServiceAccount
│   ├── serviceaccount-ops-team.yaml     # 운영팀 ServiceAccount
│   ├── role-dev-team-readonly.yaml      # 개발팀 읽기 전용 권한
│   ├── role-ops-team.yaml               # 운영팀 권한 정의
│   ├── rolebinding-dev-team.yaml        # 개발팀 권한 바인딩
│   └── rolebinding-ops-team.yaml        # 운영팀 권한 바인딩
├── clusterrole-argocd-sync.yaml         # ArgoCD Sync 권한 (ClusterRole)
└── clusterrolebinding-dev-team-argocd.yaml  # 개발팀 ArgoCD Sync 바인딩
```

## ServiceAccount 토큰 생성

각 팀의 ServiceAccount 토큰을 생성하여 CI/CD 파이프라인이나 개발자에게 배포합니다.

### 개발팀 토큰 생성 (Staging)
```bash
kubectl create token dev-team -n staging --duration=8760h
```

### 개발팀 토큰 생성 (Production - 읽기 전용)
```bash
kubectl create token dev-team -n production --duration=8760h
```

### 운영팀 토큰 생성 (Staging)
```bash
kubectl create token ops-team -n staging --duration=8760h
```

### 운영팀 토큰 생성 (Production)
```bash
kubectl create token ops-team -n production --duration=8760h
```

## 권한 테스트

### 개발팀 권한 테스트 (Staging)
```bash
# 토큰으로 인증
export DEV_TOKEN=$(kubectl create token dev-team -n staging --duration=1h)

# Deployment 생성 테스트 (성공해야 함)
kubectl --token=$DEV_TOKEN -n staging create deployment test --image=nginx

# Secret 생성 테스트 (실패해야 함)
kubectl --token=$DEV_TOKEN -n staging create secret generic test --from-literal=key=value

# Deployment 삭제 테스트 (실패해야 함)
kubectl --token=$DEV_TOKEN -n staging delete deployment test
```

### 개발팀 권한 테스트 (Production - 읽기 전용)
```bash
# 토큰으로 인증
export DEV_TOKEN=$(kubectl create token dev-team -n production --duration=1h)

# Pod 조회 테스트 (성공해야 함)
kubectl --token=$DEV_TOKEN -n production get pods

# Deployment 생성 테스트 (실패해야 함)
kubectl --token=$DEV_TOKEN -n production create deployment test --image=nginx
```

## ArgoCD UI 접근

개발팀은 ArgoCD UI에서 다음 작업이 가능합니다:
- ✅ Application 조회
- ✅ Application Sync (배포 트리거)
- ❌ Application 생성/삭제/설정 변경

운영팀은 ArgoCD에서 모든 작업이 가능합니다.

## 보안 고려사항

1. **Secret 관리**: 개발팀은 Secret을 생성할 수 없으므로, SealedSecret을 사용하여 암호화된 Secret을 Git에 커밋합니다.
2. **토큰 만료**: ServiceAccount 토큰은 주기적으로 갱신해야 합니다.
3. **감사 로그**: Kubernetes API 서버 감사 로그를 활성화하여 권한 사용을 모니터링합니다.
4. **네임스페이스 격리**: 각 팀은 할당된 네임스페이스에만 접근할 수 있습니다.

## 배포

RBAC 정책은 ArgoCD를 통해 자동으로 배포됩니다:

```bash
# ArgoCD Application 생성
kubectl apply -f apps/infra/rbac.yaml

# 동기화 상태 확인
argocd app get rbac-policies
```

## 문제 해결

### 권한 거부 오류
```bash
# 현재 사용자의 권한 확인
kubectl auth can-i --list --as=system:serviceaccount:staging:dev-team -n staging

# 특정 작업 권한 확인
kubectl auth can-i create deployments --as=system:serviceaccount:staging:dev-team -n staging
```

### ServiceAccount 확인
```bash
# ServiceAccount 목록
kubectl get sa -n staging
kubectl get sa -n production

# RoleBinding 확인
kubectl get rolebinding -n staging
kubectl get rolebinding -n production
```

## 참고 자료

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [ArgoCD RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
