module lang::sml::Language

import lang::delta::Effect;
import lang::delta::Language;

import lang::sml::Generator;
import lang::sml::PreMigrator;
import lang::sml::PostMigrator;

private Component preMigrator = lang::sml::PreMigrator::runPreMigrate;
private Component postMigrator = lang::sml::PostMigrator::runPostMigrate;
private Component generator = lang::sml::Generator::runGenerate;

public Language SML_Language = language("sml", preMigrator, postMigrator, generator);

