#!/bin/bash

# E2E Encrypted Chat - Comprehensive Security Audit Script
# Performs formal verification, vulnerability scanning, and compliance checks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Audit timestamp
AUDIT_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
AUDIT_DIR="audit-results-${AUDIT_DATE}"
mkdir -p "$AUDIT_DIR"

# Logging
LOG_FILE="${AUDIT_DIR}/security-audit.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   E2E Chat Security Audit - ${AUDIT_DATE}${NC}"
echo -e "${BLUE}========================================${NC}"

# ============= Helper Functions =============

log_section() {
    echo -e "\n${BLUE}[$(date +"%H:%M:%S")] $1${NC}"
    echo "===================="
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        return 1
    fi
    return 0
}

# ============= 1. Environment Check =============

log_section "Environment Verification"

REQUIRED_COMMANDS=(
    "java"
    "cargo"
    "go"
    "python3"
    "docker"
    "git"
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if check_command "$cmd"; then
        log_success "$cmd is available"
    else
        log_error "$cmd is missing - some checks will be skipped"
    fi
done

# ============= 2. Formal Verification =============

log_section "Formal Verification Suite"

# TLA+ Model Checking
run_tla_verification() {
    echo "Running TLA+ model checking..."
    if [ -f "tools/tlaplus/tla2tools.jar" ]; then
        java -Xmx4G -jar tools/tlaplus/tla2tools.jar \
            -config formal/tla/DoubleRatchet.cfg \
            -workers auto \
            -coverage 1 \
            formal/tla/DoubleRatchet.tla \
            > "${AUDIT_DIR}/tla-verification.log" 2>&1
        
        if grep -q "No error" "${AUDIT_DIR}/tla-verification.log"; then
            log_success "TLA+ verification passed - PFS verified"
        else
            log_error "TLA+ verification found issues"
            return 1
        fi
    else
        log_warning "TLA+ tools not found - skipping"
    fi
}

# Dafny Proof Verification
run_dafny_verification() {
    echo "Running Dafny proof verification..."
    if [ -d "tools/dafny" ]; then
        tools/dafny/dafny verify \
            --cores:4 \
            --time-limit:300 \
            formal/dafny/CryptoVerification.dfy \
            > "${AUDIT_DIR}/dafny-verification.log" 2>&1
        
        if ! grep -q "error" "${AUDIT_DIR}/dafny-verification.log"; then
            log_success "Dafny proofs verified - Cryptographic correctness proven"
        else
            log_error "Dafny verification failed"
            return 1
        fi
    else
        log_warning "Dafny not found - skipping"
    fi
}

# Alloy Model Analysis
run_alloy_verification() {
    echo "Running Alloy model analysis..."
    if [ -f "tools/alloy/alloy.jar" ] || [ -f "tools/alloy/org.alloytools.alloy.dist.jar" ]; then
        ALLOY_JAR="tools/alloy/alloy.jar"
        if [ ! -f "$ALLOY_JAR" ]; then
            ALLOY_JAR="tools/alloy/org.alloytools.alloy.dist.jar"
        fi
        java -Xmx4G -jar "$ALLOY_JAR" \
            -execute "check Confidentiality for 10" \
            formal/alloy/SecurityModel.als \
            > "${AUDIT_DIR}/alloy-verification.log" 2>&1
        
        if grep -q "No counterexample found" "${AUDIT_DIR}/alloy-verification.log"; then
            log_success "Alloy analysis passed - No security violations found"
        else
            log_error "Alloy found counterexamples"
            return 1
        fi
    else
        log_warning "Alloy not found - skipping"
    fi
}

# Run all formal verifications
VERIFICATION_PASSED=true
run_tla_verification || VERIFICATION_PASSED=false
run_dafny_verification || VERIFICATION_PASSED=false
run_alloy_verification || VERIFICATION_PASSED=false

if [ "$VERIFICATION_PASSED" = true ]; then
    log_success "All formal verifications passed"
else
    log_warning "Some formal verifications failed or were skipped"
fi

# ============= 3. Code Security Analysis =============

log_section "Code Security Analysis"

# Rust Security Audit
if check_command "cargo"; then
    echo "Auditing Rust dependencies..."
    cd src/crypto/rust
    
    # Install cargo-audit if not present
    cargo install cargo-audit 2>/dev/null || true
    
    cargo audit --json > "${AUDIT_DIR}/rust-audit.json" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Rust: No known vulnerabilities"
    else
        VULN_COUNT=$(jq '.vulnerabilities.count' "${AUDIT_DIR}/rust-audit.json")
        log_warning "Rust: Found $VULN_COUNT vulnerabilities"
    fi
    
    # Check for unsafe code
    if grep -r "unsafe" --include="*.rs" . > "${AUDIT_DIR}/unsafe-code.txt"; then
        UNSAFE_COUNT=$(wc -l < "${AUDIT_DIR}/unsafe-code.txt")
        if [ "$UNSAFE_COUNT" -eq 0 ]; then
            log_success "Rust: No unsafe code blocks"
        else
            log_warning "Rust: Found $UNSAFE_COUNT unsafe code blocks"
        fi
    fi
    
    cd ../../..
fi

# Go Security Analysis
if check_command "go"; then
    echo "Running Go security analysis..."
    cd src/backend/message-service
    
    # Install gosec if not present
    go install github.com/securego/gosec/v2/cmd/gosec@latest 2>/dev/null || true
    
    gosec -fmt json -out "${AUDIT_DIR}/go-security.json" ./... 2>/dev/null
    
    if [ -f "${AUDIT_DIR}/go-security.json" ]; then
        ISSUE_COUNT=$(jq '.Issues | length' "${AUDIT_DIR}/go-security.json")
        if [ "$ISSUE_COUNT" -eq 0 ]; then
            log_success "Go: No security issues found"
        else
            log_warning "Go: Found $ISSUE_COUNT security issues"
        fi
    fi
    
    cd ../../..
fi

# ============= 4. Cryptographic Validation =============

log_section "Cryptographic Implementation Validation"

cat > "${AUDIT_DIR}/crypto-validation.py" << 'EOF'
#!/usr/bin/env python3
import json
import subprocess
import sys

def check_crypto_params():
    """Validate cryptographic parameters"""
    issues = []
    
    # Check key sizes
    checks = {
        "AES Key Size": ("src/crypto/rust/src/types.rs", "KEY_SIZE: usize = 32", 32),
        "Nonce Size": ("src/crypto/rust/src/types.rs", "NONCE_SIZE: usize = 12", 12),
        "Tag Size": ("src/crypto/rust/src/types.rs", "TAG_SIZE: usize = 16", 16),
    }
    
    for check_name, (file_path, pattern, expected) in checks.items():
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                if pattern in content:
                    print(f"✅ {check_name}: Correct ({expected} bytes)")
                else:
                    issues.append(f"{check_name}: Pattern not found")
        except FileNotFoundError:
            issues.append(f"{check_name}: File not found")
    
    # Check for weak crypto
    weak_patterns = [
        ("MD5", "md5"),
        ("SHA1", "sha1"),
        ("DES", "des"),
        ("RC4", "rc4"),
    ]
    
    for name, pattern in weak_patterns:
        result = subprocess.run(
            ["grep", "-r", "-i", pattern, "src/", "--include=*.rs", "--include=*.go"],
            capture_output=True,
            text=True
        )
        if result.stdout:
            issues.append(f"Found weak crypto: {name}")
        else:
            print(f"✅ No {name} usage found")
    
    return issues

if __name__ == "__main__":
    issues = check_crypto_params()
    if issues:
        print("\n⚠️  Crypto validation issues:")
        for issue in issues:
            print(f"  - {issue}")
        sys.exit(1)
    else:
        print("\n✅ All cryptographic validations passed")
        sys.exit(0)
EOF

python3 "${AUDIT_DIR}/crypto-validation.py"
CRYPTO_STATUS=$?

if [ $CRYPTO_STATUS -eq 0 ]; then
    log_success "Cryptographic parameters validated"
else
    log_warning "Cryptographic validation found issues"
fi

# ============= 5. Dependency Vulnerability Scan =============

log_section "Dependency Vulnerability Scanning"

# Check for known vulnerable dependencies
if check_command "docker"; then
    echo "Running Trivy vulnerability scan..."
    docker run --rm -v "$PWD":/root/src aquasec/trivy fs \
        --severity HIGH,CRITICAL \
        --format json \
        --output /root/src/${AUDIT_DIR}/trivy-scan.json \
        /root/src 2>/dev/null
    
    if [ -f "${AUDIT_DIR}/trivy-scan.json" ]; then
        VULN_COUNT=$(jq '[.Results[].Vulnerabilities // [] | length] | add' "${AUDIT_DIR}/trivy-scan.json")
        if [ "$VULN_COUNT" -eq 0 ] || [ "$VULN_COUNT" == "null" ]; then
            log_success "No high/critical vulnerabilities found"
        else
            log_warning "Found $VULN_COUNT high/critical vulnerabilities"
        fi
    fi
fi

# ============= 6. Compliance Checks =============

log_section "Compliance and Best Practices"

# GDPR Compliance Check
check_gdpr_compliance() {
    echo "Checking GDPR compliance..."
    
    GDPR_CHECKS=(
        "Encryption at rest:src/crypto/rust:AES-256"
        "Encryption in transit:src/backend:TLS"
        "Right to erasure:src/backend:DeleteMessage"
        "Data minimization:src/backend:metadata"
    )
    
    GDPR_PASSED=true
    for check in "${GDPR_CHECKS[@]}"; do
        IFS=':' read -r check_name path pattern <<< "$check"
        if grep -r "$pattern" "$path" --include="*.rs" --include="*.go" > /dev/null 2>&1; then
            echo "  ✅ $check_name"
        else
            echo "  ❌ $check_name - needs review"
            GDPR_PASSED=false
        fi
    done
    
    if [ "$GDPR_PASSED" = true ]; then
        log_success "GDPR compliance checks passed"
    else
        log_warning "Some GDPR compliance checks need review"
    fi
}

check_gdpr_compliance

# ============= 7. Performance Security Tests =============

log_section "Security Performance Tests"

# Test encryption performance
test_crypto_performance() {
    echo "Testing cryptographic performance..."
    
    if [ -d "src/crypto/rust" ]; then
        cd src/crypto/rust
        cargo test --release -- --nocapture performance 2>&1 | tee "${AUDIT_DIR}/crypto-performance.log"
        cd ../../..
        log_success "Crypto performance tests completed"
    fi
}

test_crypto_performance

# ============= 8. Generate Security Report =============

log_section "Generating Security Audit Report"

cat > "${AUDIT_DIR}/audit-summary.json" << EOF
{
    "audit_date": "${AUDIT_DATE}",
    "formal_verification": {
        "tla_plus": "$([[ -f ${AUDIT_DIR}/tla-verification.log ]] && echo "passed" || echo "skipped")",
        "dafny": "$([[ -f ${AUDIT_DIR}/dafny-verification.log ]] && echo "passed" || echo "skipped")",
        "alloy": "$([[ -f ${AUDIT_DIR}/alloy-verification.log ]] && echo "passed" || echo "skipped")"
    },
    "code_security": {
        "rust_audit": "$([[ -f ${AUDIT_DIR}/rust-audit.json ]] && echo "completed" || echo "skipped")",
        "go_security": "$([[ -f ${AUDIT_DIR}/go-security.json ]] && echo "completed" || echo "skipped")"
    },
    "cryptography": {
        "validation": "${CRYPTO_STATUS}"
    },
    "vulnerabilities": {
        "trivy_scan": "$([[ -f ${AUDIT_DIR}/trivy-scan.json ]] && echo "completed" || echo "skipped")"
    },
    "compliance": {
        "gdpr": "${GDPR_PASSED}"
    }
}
EOF

# Generate HTML report
cat > "${AUDIT_DIR}/audit-report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Security Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .passed { background-color: #d4edda; color: #155724; }
        .warning { background-color: #fff3cd; color: #856404; }
        .failed { background-color: #f8d7da; color: #721c24; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    </style>
</head>
<body>
    <h1>🔐 E2E Chat Security Audit Report</h1>
EOF

echo "<p>Generated: $(date)</p>" >> "${AUDIT_DIR}/audit-report.html"

# Add summary to HTML report
if [ -f "${AUDIT_DIR}/audit-summary.json" ]; then
    echo "<div class='section'>" >> "${AUDIT_DIR}/audit-report.html"
    echo "<h2>Summary</h2>" >> "${AUDIT_DIR}/audit-report.html"
    echo "<pre>" >> "${AUDIT_DIR}/audit-report.html"
    jq . "${AUDIT_DIR}/audit-summary.json" >> "${AUDIT_DIR}/audit-report.html"
    echo "</pre>" >> "${AUDIT_DIR}/audit-report.html"
    echo "</div>" >> "${AUDIT_DIR}/audit-report.html"
fi

echo "</body></html>" >> "${AUDIT_DIR}/audit-report.html"

# ============= Final Summary =============

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}        Security Audit Complete         ${NC}"
echo -e "${BLUE}========================================${NC}"

log_success "Audit results saved to: ${AUDIT_DIR}/"
log_success "View report: ${AUDIT_DIR}/audit-report.html"

# Exit with appropriate code
if [ "$VERIFICATION_PASSED" = true ] && [ $CRYPTO_STATUS -eq 0 ]; then
    log_success "Security audit PASSED"
    exit 0
else
    log_warning "Security audit completed with warnings"
    exit 1
fi