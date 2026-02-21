#!/usr/bin/env bash

set -eux

dotnet tool restore
dotnet restore Source/Letterbook/Letterbook.csproj
dotnet build Source/Letterbook/Letterbook.csproj
dotnet run --project Source/Letterbook/Letterbook.csproj -c Debug --launch-profile sandcastle
