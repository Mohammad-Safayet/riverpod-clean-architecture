# Layers

The rules themselves are in `AGENTS.md` and enforced by `test/architecture_test.dart`. This page explains why, and how to move between the two feature shapes.

## Why two shapes

Clean architecture pays off when there is logic to protect; on a screen that lists API data it's three extra files that forward a call. So each feature picks:

```
full                                   lite
features/auth/                         features/products/
  auth_providers.dart  (wiring)          data/
  domain/                                  models/        ProductModel (UI uses it)
    entities/          User                sources/       ProductRemoteSource
    repositories/      AuthRepository      repositories/  ProductRepository (concrete + provider)
    usecases/          LoginUseCase      presentation/
  data/                                    notifiers/ screens/ widgets/ state/
    models/            LoginResponseModel
    sources/           AuthRemoteSource
    repositories/      AuthRepositoryImpl
  presentation/
```

Dependency direction (arrows = "imports"):

```
full:  presentation → <feature>_providers → data → domain ← presentation
lite:  presentation → data/repositories, data/models
both:  everything → core/        features → app/router/routes.dart only
```

`<feature>_providers.dart` is the composition point for a full feature: the only file that names both `XRepositoryImpl` and the domain interface. Presentation reads use cases from it, so it never sees `data/`.

## The repository is the seam

Notifiers never call a remote source. Every read/write goes through the repository (lite) or a use case → repository (full). When offline support arrives, the repository decides network vs cache and nothing above it changes.

## Promoting lite → full

Do it when the feature gains business rules, a local cache, or a second source.

1. Create `domain/entities/<model>.dart` (freezed, no json) with what the UI needs.
2. Add `toEntity()` as an extension in the model file.
3. Move the repository's public API into `domain/repositories/<model>_repository.dart` as an `abstract interface class`; rename the concrete class to `<Model>RepositoryImpl implements <Model>Repository`, returning entities.
4. Add use cases in `domain/usecases/` (one per action).
5. Create `<feature>_providers.dart` with the repository and use-case providers; delete the provider from the old repository file.
6. Point notifiers/screens at use cases and entities; remove every `data/` import from `presentation/`.
7. `make gen && make check`: the architecture test now applies the full-feature rules because `domain/` exists.

Tip: `make feature name=tmp model=<model>` generates a full skeleton you can copy from, then delete.
