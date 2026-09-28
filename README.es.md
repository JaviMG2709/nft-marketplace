# Marketplace de NFT — Compraventa de ERC-721 a precio fijo con comisiones

[English](README.md) | [Español](README.es.md)

NFT Marketplace es un proyecto de aprendizaje en Solidity desarrollado con Foundry. Es un marketplace no custodial en el que los propietarios pueden crear listados de ERC-721 a precio fijo, los compradores pueden adquirirlos con ETH y el marketplace cobra comisiones a vendedores y compradores.

## Funcionalidades

- `listNFT(nftAddress, tokenId, price)` crea un listado a precio fijo para un ERC-721 propiedad de quien realiza la llamada.
- El vendedor paga una comisión no reembolsable al crear el listado.
- `buyNFT(nftAddress, tokenId)` exige que el comprador pague el precio anunciado más su comisión. El vendedor recibe el precio completo del listado.
- `cancelList(nftAddress, tokenId)` permite cancelar el listado únicamente a su vendedor. La comisión del listado no se devuelve.
- La comisión inicial del marketplace es del **2,5 %**, representada mediante `250` puntos básicos. `10.000` puntos básicos representan el 100 %.
- Cada listado guarda la comisión vigente en el momento de su creación. Los cambios posteriores no afectan a los listados existentes.
- `setFee(newFeeBps)` permite únicamente al owner actualizar la comisión para futuros listados. Actualmente el contrato no establece una comisión máxima.
- `withdrawFees()` permite únicamente al owner retirar las comisiones acumuladas por el marketplace.
- `calculateFee(price, feeBps)` calcula las comisiones mediante `Math.mulDiv` de OpenZeppelin, que ofrece precisión completa.
- `ReentrancyGuard` protege las operaciones de listado, compra, cancelación y retirada de comisiones.
- Se emiten eventos al listar, vender o cancelar un NFT y al actualizar o retirar la comisión.

## Funcionamiento de las comisiones

Para un NFT listado por `1 ETH` con la comisión inicial del 2,5 %:

| Acción | Pagador | Cantidad |
| --- | --- | ---: |
| Crear el listado | Vendedor | `0,025 ETH` |
| Comprar el NFT | Comprador | `1,025 ETH` |
| Recibir el precio de venta | Vendedor | `1 ETH` |
| Comisiones totales | Marketplace | `0,05 ETH` |

El NFT permanece en la cartera del vendedor mientras está listado. Para que la compra pueda completarse, el vendedor debe autorizar previamente al marketplace para transferir el token. Si se cancela el listado, su comisión permanece en el marketplace.

## Estado del despliegue

El marketplace todavía no se ha desplegado en una red pública. Actualmente el repositorio no contiene un script de despliegue ni transacciones de despliegue registradas.

## Tecnologías

- Solidity `0.8.34`
- Foundry y Forge para compilación, tests, formato y cobertura
- OpenZeppelin Contracts para `IERC721`, `Ownable`, `ReentrancyGuard` y `Math`
- GitHub Actions para integración continua

## Estructura del proyecto

| Ruta | Propósito |
| --- | --- |
| `src/NFTMarketplace.sol` | Lógica del marketplace, listados, compras, cancelaciones y comisiones |
| `test/NFTMarketplaceTest.t.sol` | Tests unitarios y ERC-721 simulado utilizado en ellos |
| `.github/workflows/test.yml` | Comprobaciones de formato, compilación y tests en CI |
| `foundry.toml` | Configuración de Foundry |
| `lib/` | Submódulos de Git con las dependencias de Foundry y OpenZeppelin |

## Primeros pasos

Instala [Foundry](https://getfoundry.sh/) y Git. Después, clona el repositorio junto con sus submódulos:

```bash
git clone --recurse-submodules <repository-url>
cd nft-marketplace
```

Si clonaste el repositorio sin los submódulos:

```bash
git submodule update --init --recursive
```

Compila los contratos y comprueba su formato:

```bash
forge build
forge fmt --check
```

Ejecuta los tests y el informe de cobertura:

```bash
forge test -vvv
forge coverage
```

## Tests y alcance actual

El proyecto contiene actualmente **22 tests automatizados** que comprueban el minteo del NFT simulado, los listados y sus cancelaciones, las compras, las transferencias de NFT, los pagos al vendedor, las comisiones de vendedores y compradores, las comisiones fijadas por listado, los permisos del owner y la retirada de fondos.

La cobertura actual de `src/NFTMarketplace.sol` es:

- Líneas: **100 %**
- Sentencias: **100 %**
- Funciones: **100 %**
- Ramas: **88,89 %**

Las dos ramas no cubiertas corresponden a los casos en los que un contrato que actúa como vendedor u owner del marketplace rechaza deliberadamente una transferencia de ETH.

El workflow de GitHub Actions ejecuta las comprobaciones de formato, la compilación y todos los tests en cada push y pull request.

Este es un proyecto de aprendizaje y no ha sido auditado para utilizarse en producción. La versión actual admite ventas de ERC-721 a precio fijo pagadas con ETH. Todavía no incluye subastas, ofertas, pagos con ERC-20, royalties ERC-2981, pausado, un límite máximo para la comisión, paginación de listados ni un índice on-chain. La propiedad o autorización de un NFT también puede cambiar después de crear el listado, haciendo que una compra posterior revierta.

## Qué estoy aprendiendo

- Crear un marketplace no custodial para tokens ERC-721.
- Aplicar el patrón checks-effects-interactions y protección contra reentradas.
- Representar porcentajes mediante puntos básicos y calcular comisiones de forma segura.
- Gestionar configuración y retiradas restringidas al owner.
- Comprobar operaciones correctas, reverts esperados, balances, transferencias de propiedad y control de acceso con Foundry.
- Medir la cobertura de contratos inteligentes y entender las ramas no cubiertas.

## Próximos pasos

- Añadir un script de despliegue y desplegar el marketplace en una testnet.
- Crear un frontend para conectar una cartera, consultar listados, aprobar NFT, listar, comprar y cancelar.
- Añadir un backend o indexador de blockchain que procese los eventos y permita consultar el historial de listados.
- Añadir paginación o una estrategia de indexación para los listados activos.
- Valorar soporte para royalties ERC-2981 y pagos con tokens ERC-20.
- Valorar una comisión máxima, pausado y transferencia de propiedad en dos pasos para mejorar la administración.
- Mejorar la gestión de pagos para que los contratos que rechacen ETH no puedan bloquear compras o retiradas.
- Ejecutar análisis estático y realizar una revisión de seguridad antes de cualquier despliegue en producción.
