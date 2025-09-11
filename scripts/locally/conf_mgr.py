#!/usr/bin/env python3
"""
Configuration Manager

Handles loading and managing configuration settings from various sources.
Supports environment variables, config files, and default values.
"""

import json
import os
from typing import Any, Dict, Optional


class ConfigManager:
    """
    Configuration manager for session management systems.

    Handles loading configuration from environment variables, config files,
    and provides default values when necessary.
    """

    def __init__(
        self,
        config_file: Optional[str] = None,
        env_prefix: str = "SESSION_"
    ):
        """
        Initialize the configuration manager.

        Args:
            config_file: Path to a JSON configuration file
            env_prefix: Prefix for environment variables to load
        """
        self.config = {}
        self.env_prefix = env_prefix

        # Load default configuration
        self._load_defaults()

        # Load from config file if provided
        if config_file and os.path.exists(config_file):
            self._load_from_file(config_file)

        # Load from environment variables (highest priority)
        self._load_from_env()

    def _load_defaults(self):
        """Load default configuration values."""
        self.config = {
            # General settings
            "session_expiry_minutes": 60,
            "privacy_mode": True,

            # Redis settings
            "redis_host": "localhost",
            "redis_port": 6379,
            "redis_db": 0,
            "redis_password": None,

            # File storage settings
            "storage_dir": "./sessions",
            "cleanup_interval_minutes": 5,

            # Memory storage settings
            "cleanup_interval_seconds": 60,

            # Security settings
            "token_bytes": 32,
            "rate_limit_attempts": 5,
            "rate_limit_window_minutes": 15
        }

    def _load_from_file(self, config_file: str):
        """
        Load configuration from a JSON file.

        Args:
            config_file: Path to a JSON configuration file
        """
        try:
            with open(config_file, 'r') as f:
                file_config = json.load(f)

            # Update config with file values
            for key, value in file_config.items():
                self.config[key.lower()] = value
        except Exception as e:
            print(f"Warning: Failed to load config file: {e}")

    def _load_from_env(self):
        """Load configuration from environment variables."""
        for env_var, value in os.environ.items():
            # Only process variables with the specified prefix
            if env_var.startswith(self.env_prefix):
                # Convert to lowercase key without prefix
                key = env_var[len(self.env_prefix):].lower()

                # Convert value types appropriately
                if value.lower() in ("true", "yes", "1"):
                    self.config[key] = True
                elif value.lower() in ("false", "no", "0"):
                    self.config[key] = False
                elif value.isdigit():
                    self.config[key] = int(value)
                elif value.replace(".", "", 1).isdigit() and value.count(".") == 1:
                    self.config[key] = float(value)
                else:
                    self.config[key] = value

    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value.

        Args:
            key: The configuration key to retrieve
            default: Value to return if key is not found

        Returns:
            The configuration value
        """
        return self.config.get(key.lower(), default)

    def set(self, key: str, value: Any):
        """
        Set a configuration value.

        Args:
            key: The configuration key to set
            value: The value to set
        """
        self.config[key.lower()] = value

    def as_dict(self) -> Dict[str, Any]:
        """
        Get the entire configuration as a dictionary.

        Returns:
            Dict containing all configuration values
        """
        return self.config.copy()


if __name__ == "__main__":
    # Simple usage example
    config = ConfigManager()

    # Get a configuration value
    expiry = config.get("session_expiry_minutes")
    print(f"Session expiry: {expiry} minutes")

    # Set a configuration value
    config.set("session_expiry_minutes", 120)
    print(f"New session expiry: {config.get('session_expiry_minutes')} minutes")

    # Get all configuration
    print("\nAll configuration:")
    for key, value in config.as_dict().items():
        print(f"{key}: {value}")
