package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestModuleStructure(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "..",
		NoColor:      true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

func TestModuleFilesExist(t *testing.T) {
	t.Parallel()

	requiredFiles := []string{
		"main.tf",
		"variables.tf",
		"outputs.tf",
		"versions.tf",
		"README.md",
		"LICENSE",
		"examples/basic/main.tf",
	}

	for _, file := range requiredFiles {
		filePath := "../" + file
		_, err := os.Stat(filePath)
		assert.NoError(t, err, "Required file %s should exist", file)
	}
}

func TestBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		NoColor:      true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}
