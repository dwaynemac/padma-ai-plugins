# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "yaml"

class MarketplaceCompatibilityTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  AGENT_PLUGIN_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
  AGENT_PLUGIN_MCP_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"
  PORTABLE_MANIFEST_FIELDS = %w[
    $schema name version description author homepage repository license keywords extensions
  ].freeze

  def test_published_plugin_surfaces_are_compatible
    codex = read_json(".agents/plugins/marketplace.json")
    claude = read_json(".claude-plugin/marketplace.json")

    assert_equal "https://anthropic.com/claude-code/marketplace.schema.json",
                 claude.fetch("$schema")
    assert_equal "PADMA", claude.dig("owner", "name")
    assert_equal codex.fetch("plugins").map { |plugin| plugin.fetch("name") }.sort,
                 claude.fetch("plugins").map { |plugin| plugin.fetch("name") }.sort

    codex.fetch("plugins").each do |plugin|
      assert_equal "local", plugin.dig("source", "source")
      assert_equal "./plugins/#{plugin.fetch("name")}", plugin.dig("source", "path")
    end

    claude.fetch("plugins").each do |plugin|
      name = plugin.fetch("name")
      source = plugin.fetch("source")

      assert_equal "./plugins/#{name}", source
      assert File.directory?(File.join(ROOT, source))

      codex_manifest = read_json("plugins/#{name}/.codex-plugin/plugin.json")
      claude_manifest = read_json("plugins/#{name}/.claude-plugin/plugin.json")
      portable_manifest = read_json("plugins/#{name}/plugin.json")

      assert_equal name, claude_manifest.fetch("name")
      assert_equal codex_manifest.fetch("version"), claude_manifest.fetch("version")
      assert_equal AGENT_PLUGIN_SCHEMA, portable_manifest.fetch("$schema")
      assert_equal name, portable_manifest.fetch("name")
      assert_equal codex_manifest.fetch("version"), portable_manifest.fetch("version")
      assert_empty portable_manifest.keys - PORTABLE_MANIFEST_FIELDS
      %w[name version description author homepage repository keywords].each do |field|
        assert_equal codex_manifest[field], portable_manifest[field]
      end
      assert_equal "./skills/", claude_manifest.fetch("skills")

      assert_portable_skills(name)

      native_mcp_path = File.join(ROOT, "plugins", name, ".mcp.json")
      portable_mcp_path = File.join(ROOT, "plugins", name, "mcp.json")

      if File.file?(native_mcp_path)
        assert_equal "./.mcp.json", claude_manifest.fetch("mcpServers")
        assert File.file?(portable_mcp_path)
        assert_portable_mcp(name)
      else
        refute claude_manifest.key?("mcpServers")
        refute File.exist?(portable_mcp_path)
      end
    end
  end

  def test_money_and_learn_declare_oauth_for_openai_hosts
    %w[money learn].each do |name|
      server = read_json("plugins/#{name}/mcp.json").fetch("mcpServers").fetch(name)
      assert_equal "oauth", server.dig("extensions", "com.openai", "auth", "type")
    end
  end

  def test_crm_review_and_publication_metadata_match_portable_package
    portable = read_json("plugins/crm/plugin.json").fetch("extensions").fetch("com.openai")
    codex = read_json("plugins/crm/.codex-plugin/plugin.json")

    assert_equal portable.fetch("interface"), codex.fetch("interface")
    %w[review publication].each do |field|
      assert_equal portable.fetch(field), codex.fetch("extensions").fetch("com.openai").fetch(field)
    end
  end

  private

  def read_json(path)
    JSON.parse(File.read(File.join(ROOT, path)))
  end

  def assert_portable_skills(plugin_name)
    skill_paths = Dir[File.join(ROOT, "plugins", plugin_name, "skills", "*", "SKILL.md")]

    refute_empty skill_paths

    skill_paths.each do |path|
      frontmatter = YAML.safe_load(File.read(path).split("---", 3).fetch(1))
      name = frontmatter.fetch("name")
      description = frontmatter.fetch("description")

      assert_equal File.basename(File.dirname(path)), name
      assert_match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, name)
      assert_operator name.length, :<=, 64
      assert_operator description.length, :>=, 1
      assert_operator description.length, :<=, 1024
    end
  end

  def assert_portable_mcp(plugin_name)
    native = read_json("plugins/#{plugin_name}/.mcp.json")
    portable = read_json("plugins/#{plugin_name}/mcp.json")

    assert_equal AGENT_PLUGIN_MCP_SCHEMA, portable.fetch("$schema")
    assert_empty portable.keys - %w[$schema mcpServers]
    assert_equal native.fetch("mcpServers").keys, portable.fetch("mcpServers").keys

    portable.fetch("mcpServers").each do |name, server|
      assert_equal "streamable-http", server.fetch("type")
      assert_match(%r{\Ahttps://}, server.fetch("url"))
      assert_equal native.dig("mcpServers", name, "url"), server.fetch("url")
      assert_empty server.keys - %w[type url headers extensions]
    end
  end
end
