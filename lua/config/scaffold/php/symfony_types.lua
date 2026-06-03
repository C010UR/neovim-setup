local psr4 = require("config.scaffold.php.psr4")

---@class ConfigScaffoldPhpSymfonyTypes
local M = {}

--- Inserts namespace declaration after the `<?php` + `declare` header and
--- before any `use` imports.
---@param namespace string
---@param lines string[]
local function add_namespace(namespace, lines)
  if namespace ~= "" then
    table.insert(lines, 5, ("namespace %s;"):format(namespace))
    table.insert(lines, 6, "")
  end
end
function M.command(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Console\\Attribute\\AsCommand;",
    "use Symfony\\Component\\Console\\Command\\Command;",
    "use Symfony\\Component\\Console\\Input\\InputInterface;",
    "use Symfony\\Component\\Console\\Output\\OutputInterface;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = "#[AsCommand(name: 'app:command', description: 'App command')]"
  lines[#lines + 1] = ("final class %s extends Command"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    protected function execute(InputInterface $input, OutputInterface $output): int"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return Command::SUCCESS;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.controller(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Bundle\\FrameworkBundle\\Controller\\AbstractController;",
    "use Symfony\\Component\\HttpFoundation\\JsonResponse;",
    "use Symfony\\Component\\HttpFoundation\\Request;",
    "use Symfony\\Component\\HttpFoundation\\Response;",
    "use Symfony\\Component\\Routing\\Attribute\\Route;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = "#[Route('/')]"
  lines[#lines + 1] = ("final class %s extends AbstractController"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 1, col = 0 } }
end
function M.form_type(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Bridge\\Doctrine\\Form\\Type\\EntityType;",
    "use Symfony\\Component\\Form\\AbstractType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\CheckboxType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\ChoiceType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\CollectionType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\DateTimeType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\EmailType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\HiddenType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\IntegerType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\TextareaType;",
    "use Symfony\\Component\\Form\\Extension\\Core\\Type\\TextType;",
    "use Symfony\\Component\\Form\\FormBuilderInterface;",
    "use Symfony\\Component\\Validator\\Constraints as Assert;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s extends AbstractType"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public function buildForm(FormBuilderInterface $builder, array $options): void"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.message(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public function __construct()"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.message_handler(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Messenger\\Attribute\\AsMessageHandler;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 1, col = 0 } }
end
function M.event_listener(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\EventDispatcher\\Attribute\\AsEventListener;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 1, col = 0 } }
end
function M.voter(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Security\\Core\\Authentication\\Token\\TokenInterface;",
    "use Symfony\\Component\\Security\\Core\\Authorization\\Voter\\Voter;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s extends Voter"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    protected function supports(string $attribute, mixed $subject): bool"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return true;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = ""
  lines[#lines + 1] =
    "    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token): bool"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return true;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.twig_extension(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Twig\\Extension\\AbstractExtension;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s extends AbstractExtension"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 1, col = 0 } }
end
function M.data_transformer(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Form\\DataTransformerInterface;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s implements DataTransformerInterface"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public function transform(mixed $value): mixed"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return $value;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "    public function reverseTransform(mixed $value): mixed"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return $value;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.normalizer(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Serializer\\Normalizer\\DenormalizerInterface;",
    "use Symfony\\Component\\Serializer\\Normalizer\\NormalizerInterface;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s implements NormalizerInterface, DenormalizerInterface"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public function normalize(mixed $object, string $format = null, array $context = []): array"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return [];"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "    public function supportsNormalization(mixed $data, string $format = null): bool"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return true;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = ""
  lines[#lines + 1] =
    "    public function denormalize(mixed $data, string $type, string $format = null, array $context = []): mixed"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return null;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = ""
  lines[#lines + 1] =
    "    public function supportsDenormalization(mixed $data, string $type, string $format = null): bool"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "        return true;"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end
function M.constraint(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Validator\\Constraint;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = "#[\\Attribute]"
  lines[#lines + 1] = ("final class %s extends Constraint"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public string $message = 'The value is not valid.';"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 1, col = 0 } }
end
function M.constraint_validator(name, path)
  local namespace = psr4.namespace_for(path, psr4.project_root(path))
  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
    "use Symfony\\Component\\Validator\\Constraint;",
    "use Symfony\\Component\\Validator\\ConstraintValidator;",
    "",
  }
  add_namespace(namespace, lines)
  lines[#lines + 1] = ("final class %s extends ConstraintValidator"):format(name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = "    public function validate(mixed $value, Constraint $constraint): void"
  lines[#lines + 1] = "    {"
  lines[#lines + 1] = "    }"
  lines[#lines + 1] = "}"
  return { lines = lines, cursor = { line = #lines - 2, col = 0 } }
end

return M
