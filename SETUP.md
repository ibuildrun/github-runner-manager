# Setup Deploy Submodule

После создания репозитория `avyx-deploy` на GitHub:

```powershell
cd deploy
git push -u origin main
cd ..
git submodule add https://github.com/ibuildrun/avyx-deploy.git deploy
git commit -m "feat: add deploy as submodule"
git push origin main
```
