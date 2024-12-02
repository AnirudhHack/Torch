import React from 'react';
// import { useConnectWallet, useSetChain } from '@web3-onboard/react';
import {ethers} from 'ethers'

const ConnectWallet = () => {
  const Ethereum = {
    chainId: 1,
    currency: 'ETH',
    name: 'Ethereum Mainnet Fork',
    rpcUrl: `https://virtual.mainnet.rpc.tenderly.co/${process.env.NEXT_PUBLIC_TENDERLY_ETH_VIRTUAL_TESTNET}`
  }
    const [connected, setConnected] = React.useState(false);

    React.useEffect(() => {
        const checkConnection = async () => {
          if (window.ethereum) {
            try {
              const provider = new ethers.providers.Web3Provider(window.ethereum);
              const network = await provider.getNetwork();
              setConnected(network.chainId == Ethereum.chainId);
            } catch (error) {
              console.error('Error checking connection:', error);
              setConnected(false);
            }
          } else {
            setConnected(false);
          }
        };
      
        checkConnection(); // Initial check
      
        const intervalId = setInterval(checkConnection, 3000); // Call checkConnection every 3 seconds
      
        return () => clearInterval(intervalId); // Cleanup function to clear the interval
      }, []);
  
    const connectWallet = async () => {
      if (window.ethereum) {
        try {
          await window.ethereum.request({ method: 'eth_requestAccounts' });
          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const network = await provider.getNetwork();
  
          if (network.chainId === Ethereum.chainId) {
            setConnected(true);
          } else {
            // Add network if not present in wallet
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [{
                chainId: `0x${Ethereum.chainId.toString(16)}`,
                chainName: Ethereum.name,
                nativeCurrency: {
                  name: Ethereum.currency,
                  symbol: Ethereum.currency,
                  decimals: 18,
                },
                rpcUrls: [Ethereum.rpcUrl],
              }],
            });
          }
        } catch (error) {
          console.error('Error connecting wallet:', error);
        }
      } else {
      }
    };
    
    return(
      <button 
        className={`inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2`}
        onClick={connectWallet}
      >
        {connected ? 'Connected to Tenderly Ethereum' : 'Connect Wallet'}
      </button>
    )

};

export default ConnectWallet;