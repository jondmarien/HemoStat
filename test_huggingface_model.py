#!/usr/bin/env python3
"""
Test script to verify Hugging Face model connection for HemoStat Analyzer.

This script tests the lakhera2023/devops-slm model connection without
starting the full analyzer agent.

Usage:
    python test_huggingface_model.py
    # or: uv run python test_huggingface_model.py
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_huggingface_connection():
    """Test Hugging Face model connection and configuration."""
    
    print("=" * 70)
    print("HemoStat - Hugging Face Model Connection Test")
    print("=" * 70)
    print()
    
    # Check environment variables
    ai_model = os.getenv("AI_MODEL", "")
    hf_token = os.getenv("HUGGINGFACE_API_KEY") or os.getenv("HF_TOKEN", "")
    ai_fallback = os.getenv("AI_FALLBACK_ENABLED", "true").lower() == "true"
    
    print("📋 Configuration Check:")
    print(f"  ✓ AI_MODEL: {ai_model}")
    print(f"  ✓ HUGGINGFACE_API_KEY: {'Set (' + hf_token[:10] + '...)' if hf_token else '❌ NOT SET'}")
    print(f"  ✓ AI_FALLBACK_ENABLED: {ai_fallback}")
    print()
    
    # Verify model format
    if "/" not in ai_model:
        print("❌ ERROR: AI_MODEL doesn't look like a Hugging Face model")
        print("   Hugging Face models should be in format: username/model-name")
        print(f"   Current value: {ai_model}")
        return False
    
    if not hf_token:
        print("❌ ERROR: HUGGINGFACE_API_KEY is not set!")
        print("   Get your token from: https://huggingface.co/settings/tokens")
        return False
    
    print("✅ Configuration looks good!")
    print()
    
    # Test LangChain HuggingFaceEndpoint import
    print("📦 Testing LangChain imports...")
    try:
        from langchain_huggingface import HuggingFaceEndpoint
        print("  ✓ langchain_huggingface imported successfully")
    except ImportError as e:
        print(f"  ❌ Failed to import langchain_huggingface: {e}")
        print("     Install with: uv sync --extra agents")
        return False
    
    print()
    
    # Test model initialization
    print(f"🚀 Testing connection to {ai_model}...")
    try:
        llm = HuggingFaceEndpoint(
            repo_id=ai_model,
            temperature=0.3,
            max_new_tokens=512,
            huggingfacehub_api_token=hf_token,
        )
        print(f"  ✓ HuggingFaceEndpoint initialized successfully")
        print()
        
        # Test a simple inference
        print("🧪 Testing model inference...")
        test_prompt = "What is Docker container health monitoring?"
        
        print(f"  Prompt: '{test_prompt}'")
        print("  Waiting for response...")
        
        response = llm.invoke(test_prompt)
        
        print()
        print("  ✓ Model response received!")
        print()
        print("  Response preview (first 200 chars):")
        print("  " + "-" * 66)
        response_text = str(response)[:200]
        for line in response_text.split('\n'):
            print(f"  {line}")
        if len(str(response)) > 200:
            print("  ...")
        print("  " + "-" * 66)
        print()
        
        print("=" * 70)
        print("✅ SUCCESS! Hugging Face model is working correctly!")
        print("=" * 70)
        print()
        print("Next steps:")
        print("  1. Start Redis: docker compose up -d redis")
        print("  2. Start Analyzer: uv run python -m agents.hemostat_analyzer.main")
        print("  3. The analyzer will use your Hugging Face model for analysis")
        print()
        
        return True
        
    except Exception as e:
        print(f"  ❌ Error testing model: {e}")
        print()
        print("Troubleshooting:")
        print("  1. Check your Hugging Face token is valid")
        print("  2. Verify the model exists: https://huggingface.co/" + ai_model)
        print("  3. Ensure you have internet connection")
        print("  4. Check if the model requires authentication/acceptance")
        print()
        return False


if __name__ == "__main__":
    try:
        success = test_huggingface_connection()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
