module lang::sml::Language

import lang::sml::Generator;
import lang::sml::PreMigrator;
import lang::sml::PostMigrator;
import lang::sml::Object;

import lang::delta::Object;
import lang::delta::Language;

private Component preMigrator = lang::sml::PreMigrator::runPreMigrate;
private Component postMigrator = lang::sml::PostMigrator::runPostMigrate;
private Component generator = lang::sml::Generator::runGenerate;
private Create creator = lang::sml::Object::create;

public Language SML_Language = language("sml", preMigrator, postMigrator, generator, creator);

