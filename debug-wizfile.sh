#!/bin/bash

echo "🔍 Debugging wizexercise.txt file issue"
echo "======================================="

# Check local file
echo "1. Checking local file..."
if [ -f "app/wizexercise.txt" ]; then
    echo "✅ Local file exists"
    echo "Content: $(cat app/wizexercise.txt)"
else
    echo "❌ Local file missing!"
    exit 1
fi

# Check if kubectl is connected
echo ""
echo "2. Checking kubectl connection..."
if kubectl cluster-info &> /dev/null; then
    echo "✅ kubectl connected"
else
    echo "❌ kubectl not connected"
    echo "Run: aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-dev"
    exit 1
fi

# Check for pods
echo ""
echo "3. Checking for pods..."
PODS=$(kubectl get pods -l app=wiz-todo-app --no-headers 2>/dev/null)
if [ -n "$PODS" ]; then
    echo "✅ Found pods:"
    kubectl get pods -l app=wiz-todo-app
    
    # Get first running pod
    POD_NAME=$(kubectl get pods -l app=wiz-todo-app --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD_NAME" ]; then
        echo ""
        echo "4. Checking file in container..."
        echo "Pod: $POD_NAME"
        
        echo "Files in /app/:"
        kubectl exec $POD_NAME -- ls -la /app/
        
        echo ""
        echo "Checking wizexercise.txt:"
        if kubectl exec $POD_NAME -- test -f /app/wizexercise.txt; then
            echo "✅ File exists in container"
            echo "Content:"
            kubectl exec $POD_NAME -- cat /app/wizexercise.txt
        else
            echo "❌ File missing in container!"
            echo "This means the Docker build didn't copy it properly"
        fi
    else
        echo "❌ No running pods found"
        echo "Pod status:"
        kubectl get pods -l app=wiz-todo-app
        echo ""
        echo "Check pod logs:"
        kubectl logs -l app=wiz-todo-app --tail=20
    fi
else
    echo "❌ No pods found"
    echo "You need to deploy the application:"
    echo "kubectl apply -f k8s/app/"
fi

echo ""
echo "🔍 Debug complete!"