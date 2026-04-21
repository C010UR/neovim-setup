local toml_standalone = {
  filetypes = { "toml" },
  extensions = { "toml" },
}

local json_standalone = {
  filetypes = { "json", "jsonc" },
  extensions = { "json", "jsonc", "json5" },
}

local yaml_standalone = {
  filetypes = { "yaml" },
  extensions = { "yaml", "yml" },
}

local xml_standalone = {
  filetypes = { "xml", "xsd", "xsl", "svg" },
  extensions = { "xml", "xsd", "xsl", "xslt", "svg" },
}

local dockerfile_standalone = {
  filetypes = { "dockerfile" },
  filenames = { "Dockerfile", "Containerfile" },
}

return {
  -- Shared support for common configuration files, dotfiles, and related markup.
  {
    "b0o/SchemaStore.nvim",
    version = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local function add(lang)
        if type(opts.ensure_installed) == "table" and not vim.tbl_contains(opts.ensure_installed, lang) then
          table.insert(opts.ensure_installed, lang)
        end
      end

      vim.filetype.add({
        extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi" },
        filename = {
          ["vifmrc"] = "vim",
        },
        pattern = {
          [".*/waybar/config"] = "jsonc",
          [".*/mako/config"] = "dosini",
          [".*/kitty/.+%.conf"] = "kitty",
          [".*/hypr/.+%.conf"] = "hyprlang",
        },
      })
      vim.treesitter.language.register("bash", "kitty")

      for _, lang in ipairs({ "json5", "yaml", "xml", "dockerfile", "git_config" }) do
        add(lang)
      end

      local xdg_config = vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config"
      local function have(path)
        return vim.uv.fs_stat(xdg_config .. "/" .. path) ~= nil
      end

      if have("hypr") then
        add("hyprlang")
      end
      if have("rofi") or have("wofi") then
        add("rasi")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    opts = {
      servers = {
        taplo = {
          standalone = toml_standalone,
        },
        dockerls = {
          standalone = dockerfile_standalone,
        },
        docker_compose_language_service = {
          workspace_required = true,
          root_markers = { "compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml" },
        },
        jsonls = {
          standalone = json_standalone,
          before_init = function(_, new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = { enable = true },
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          standalone = yaml_standalone,
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          before_init = function(_, new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend(
              "force",
              new_config.settings.yaml.schemas or {},
              require("schemastore").yaml.schemas()
            )
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = { enable = true },
              validate = true,
              schemaStore = {
                enable = false,
                url = "",
              },
            },
          },
        },
        lemminx = {
          enabled = true,
          standalone = xml_standalone,
        },
      },
    },
  },
  {
    "https://tangled.org/cuducos.me/yaml.nvim",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      {
        "<leader>fy",
        function()
          require("yaml_nvim").snacks()
        end,
        desc = "Find YAML Key",
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "json-lsp",
        "jq",
        "prettier",
        "yaml-language-server",
        "yamlfmt",
        "lemminx",
        "xmlformatter",
        "hadolint",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        json = { "jq" },
        jsonc = { "prettier" },
        yaml = { "yamlfmt" },
        xml = { "xmlformatter" },
        svg = { "xmlformatter" },
      },
    },
  },
}
