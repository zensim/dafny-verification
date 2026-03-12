# Dafny Verification Pipeline

End-to-end automated verification pipeline for Dafny files using GitHub Actions and AWS CodePipeline.

## Architecture

```
GitHub Repo → GitHub Actions → S3 Bucket → CodePipeline → Dev Stage (Dafny Verify) → Test Stage
                                                              ↓ (on failure)
                                                         S3 failure logs
```

## Components

### Mock Dafny Files (6 files)
- **Valid files** (3): `valid1.dfy`, `valid2.dfy`, `valid3.dfy` - Pass verification
- **Invalid files** (3): `invalid1.dfy`, `invalid2.dfy`, `invalid3.dfy` - Fail verification

### GitHub Actions Workflow
- Triggers on push to `main` branch or manual dispatch
- Syncs `.dfy` files to S3 bucket
- Triggers CodePipeline execution

### AWS CodePipeline (2 stages)
1. **Dev Stage**: Downloads files from S3, runs Dafny verification
   - On failure: Writes error logs to `s3://bucket/verification-failures/`
   - On success: Writes status to `s3://bucket/verification-success/`
2. **Test Stage**: Validates success status and proceeds

## Setup Instructions

### Prerequisites
- AWS Account
- GitHub Account
- AWS CLI configured
- Git installed

### Step 1: Deploy GitHub OIDC Provider (One-time setup)

```bash
aws cloudformation create-stack \
  --stack-name github-oidc-provider \
  --template-body file://infrastructure/github-oidc.yml \
  --capabilities CAPABILITY_IAM
```

### Step 2: Create GitHub Connection in AWS

1. Go to AWS Console → Developer Tools → Settings → Connections
2. Create a new connection to GitHub
3. Authorize the connection
4. Copy the Connection ARN

### Step 3: Deploy Pipeline Infrastructure

```bash
aws cloudformation create-stack \
  --stack-name dafny-pipeline \
  --template-body file://infrastructure/pipeline.yml \
  --parameters \
    ParameterKey=GitHubOwner,ParameterValue=YOUR_GITHUB_USERNAME \
    ParameterKey=GitHubRepo,ParameterValue=dafny-verification \
    ParameterKey=GitHubConnectionArn,ParameterValue=YOUR_CONNECTION_ARN \
  --capabilities CAPABILITY_NAMED_IAM
```

### Step 4: Get Stack Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name dafny-pipeline \
  --query 'Stacks[0].Outputs'
```

Note the following values:
- `DfyBucketName`
- `GitHubActionsRoleArn`

### Step 5: Configure GitHub Repository

1. Create a new GitHub repository named `dafny-verification`
2. Add GitHub Secrets:
   - `AWS_ROLE_ARN`: The GitHubActionsRoleArn from stack outputs
   - `DFY_BUCKET`: The DfyBucketName from stack outputs

```bash
# In your local repository
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/dafny-verification.git
git push -u origin main
```

### Step 6: Test the Pipeline

#### Test with Valid Files Only
```bash
# Remove invalid files temporarily
git rm dfy-files/invalid*.dfy
git commit -m "Test with valid files only"
git push
```

Expected: Pipeline passes both Dev and Test stages

#### Test with Invalid Files
```bash
# Restore invalid files
git checkout HEAD~1 -- dfy-files/invalid*.dfy
git commit -m "Test with invalid files"
git push
```

Expected: 
- Pipeline fails at Dev stage
- Error logs written to S3 at `s3://BUCKET/verification-failures/`
- Pipeline stops before Test stage

## Verification Results

### Success Scenario
- All `.dfy` files verify successfully
- Status written to `s3://BUCKET/verification-success/status.txt`
- Pipeline proceeds to Test stage
- Test stage completes successfully

### Failure Scenario
- One or more `.dfy` files fail verification
- Detailed error logs written to `s3://BUCKET/verification-failures/`
- `failure-summary.txt` lists all failed files
- Individual `.output` files contain Dafny error messages
- Pipeline stops at Dev stage

## View Results

### Check Pipeline Status
```bash
aws codepipeline get-pipeline-state --name dafny-verification-pipeline
```

### View Failure Logs
```bash
aws s3 ls s3://YOUR_BUCKET/verification-failures/
aws s3 cp s3://YOUR_BUCKET/verification-failures/failure-summary.txt -
```

### View CodeBuild Logs
```bash
aws logs tail /aws/codebuild/dafny-pipeline-dev-build --follow
```

## File Structure

```
.
├── dfy-files/
│   ├── valid1.dfy          # Valid: Max function
│   ├── valid2.dfy          # Valid: Array sum
│   ├── valid3.dfy          # Valid: Factorial
│   ├── invalid1.dfy        # Invalid: Division postcondition
│   ├── invalid2.dfy        # Invalid: Missing loop invariant
│   └── invalid3.dfy        # Invalid: Sqrt postcondition
├── .github/
│   └── workflows/
│       └── deploy-to-s3.yml
├── infrastructure/
│   ├── github-oidc.yml     # GitHub OIDC provider
│   └── pipeline.yml        # CodePipeline infrastructure
├── buildspec.yml           # Dev stage build spec
├── buildspec-test.yml      # Test stage build spec
└── README.md
```

## Cleanup

```bash
# Delete pipeline stack
aws cloudformation delete-stack --stack-name dafny-pipeline

# Empty and delete S3 buckets
aws s3 rm s3://dafny-pipeline-dfy-files-ACCOUNT_ID --recursive
aws s3 rb s3://dafny-pipeline-dfy-files-ACCOUNT_ID
aws s3 rm s3://dafny-pipeline-artifacts-ACCOUNT_ID --recursive
aws s3 rb s3://dafny-pipeline-artifacts-ACCOUNT_ID

# Delete OIDC provider (optional)
aws cloudformation delete-stack --stack-name github-oidc-provider
```

## Troubleshooting

### Pipeline doesn't trigger
- Check GitHub Actions logs
- Verify AWS credentials and role permissions
- Ensure S3 bucket name matches in secrets

### Dafny verification fails unexpectedly
- Check CodeBuild logs: `aws logs tail /aws/codebuild/dafny-pipeline-dev-build`
- Verify Dafny installation in buildspec.yml
- Check S3 for failure logs

### GitHub Actions fails
- Verify OIDC provider is created
- Check IAM role trust policy
- Ensure GitHub secrets are set correctly
